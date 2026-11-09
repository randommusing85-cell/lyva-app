import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/prime_plan.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/services/checkin_preferences.dart';
import 'package:lyva_app/services/export_service.dart';
import 'package:lyva_app/utils/checkin_input.dart';
import 'package:lyva_app/utils/plateau_detector.dart';
import 'package:lyva_app/screens/my_plan_screen.dart' show buildTrendPayload;
import 'fixtures/legacy_checkin.dart';
void main() {
  final now = DateTime(2026, 11, 3, 12);
  test('mood/energy or note only preserves absent measurements as null', () {
    final c = CheckInInput.parse(now: now, mood: 4, energy: 3);
    expect(c.weightKg, isNull); expect(c.waistCm, isNull); expect(c.stepsToday, isNull);
    expect(c.moodScore, 4); expect(CheckInInput.parse(now: now, note: 'hello').note, 'hello');
    expect(() => CheckInInput.parse(now: now), throwsFormatException);
  });
  test('zero steps is recorded; invalid and nonfinite measurements rejected', () {
    expect(CheckInInput.parse(now: now, steps: '0').stepsToday, 0);
    for (final weight in ['NaN', 'Infinity', '0', '-1', 'abc']) {
      expect(() => CheckInInput.parse(now: now, weight: weight), throwsFormatException);
    }
    expect(() => CheckInInput.parse(now: now, steps: '1.5'), throwsFormatException);
    expect(() => CheckInInput.parse(now: now, mood: 6), throwsFormatException);
    expect(CheckInInput.parse(now: now, waist: '80.5').weightKg, isNull);
  });
  test('trend payload averages only observed measurements and retains real zero steps', () {
    final onlyMood = CheckInInput.parse(now: now, mood: 3);
    final payload = buildTrendPayload([onlyMood]);
    expect(payload['weight']['last7_avg'], isNull); expect(payload['steps']['last7_avg'], isNull);
    final mixed = buildTrendPayload([onlyMood, CheckInInput.parse(now: now, weight: '70', steps: '0')]);
    expect(mixed['weight']['last7_avg'], 70); expect(mixed['waist']['last7_avg'], isNull); expect(mixed['steps']['last7_avg'], 0);
  });
  test('mood-only records do not become zero-weight plateau evidence', () {
    final plan = PrimePlan()..createdAt = now.subtract(const Duration(days: 60))..phase = 'deficit'..phaseStartedAt = now.subtract(const Duration(days: 30));
    final result = PlateauDetector.analyze(checkIns: List.generate(21, (i) => CheckInInput.parse(now: now.subtract(Duration(days: i)), mood: 3)), currentPlan: plan, now: now);
    expect(result.isPlateaued, isFalse); expect(result.week1Avg, isNull); expect(result.weightChangeKg, isNull);
  });
  test('frequency defaults to user choice; daily/weekly use calendar days and ignore future dates', () async {
    SharedPreferences.setMockInitialValues({}); final prefs = CheckInPreferences();
    expect(await prefs.read(), 'manual'); await prefs.save('weekly'); expect(await CheckInPreferences().read(), 'weekly');
    expect(CheckInPreferences.due('manual', null, now), isFalse);
    expect(CheckInPreferences.due('daily', DateTime(2026, 11, 2, 23, 59), now), isTrue);
    expect(CheckInPreferences.due('daily', DateTime(2026, 11, 3), now), isFalse);
    expect(CheckInPreferences.due('weekly', DateTime(2026, 10, 27, 23, 59), now), isTrue);
    expect(CheckInPreferences.due('weekly', DateTime(2026, 10, 28), now), isFalse);
    expect(CheckInPreferences.due('weekly', now.add(const Duration(days: 1)), now), isFalse);
    await expectLater(prefs.save('hourly'), throwsArgumentError);
  });
  group('isolated persistence and export', () {
    late Directory directory; late Isar db; late LyvaRepo repo;
    Future<Isar> open() => Isar.open([CheckInSchema], directory: directory.path, name: 'checkins', inspector: false);
    setUpAll(() async { await Isar.initializeIsarCore(libraries: {
      Abi.windowsX64: File('vendor/isar_flutter_libs/windows/isar.dll').absolute.path,
      Abi.linuxX64: File('vendor/isar_flutter_libs/linux/libisar.so').absolute.path,
      Abi.macosX64: File('vendor/isar_flutter_libs/macos/libisar.dylib').absolute.path,
      Abi.macosArm64: File('vendor/isar_flutter_libs/macos/libisar.dylib').absolute.path,
    }); });
    setUp(() async { directory = await Directory.systemTemp.createTemp('lyva_optional_checkin_'); db = await open(); repo = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () async => db); });
    tearDown(() async { if (db.isOpen) await db.close(deleteFromDisk: true); await directory.delete(recursive: true); });
    test('old measurements survive schema upgrade and new nulls survive reopen', () async {
      await db.close(deleteFromDisk: true);
      final oldDb = await Isar.open([legacyCheckInSchema], directory: directory.path, name: 'checkins', inspector: false);
      final old = LegacyCheckIn()..ts = DateTime(2024, 5, 6)..weightKg = 71.5..waistCm = 80.5..stepsToday = 0..note = 'Historical'..moodScore = 4;
      await oldDb.writeTxn(() async { await oldDb.collection<LegacyCheckIn>().put(old); });
      await oldDb.close(); db = await open();
      final stored = (await db.checkIns.get(old.id))!;
      expect(stored.weightKg, 71.5); expect(stored.waistCm, 80.5); expect(stored.stepsToday, 0); expect(stored.note, 'Historical');
      final moodOnly = CheckInInput.parse(now: now, mood: 3); await repo.addCheckIn(moodOnly);
      await db.close(); db = await open();
      final reopened = (await db.checkIns.get(moodOnly.id))!;
      expect(reopened.weightKg, isNull); expect(reopened.stepsToday, isNull); expect(reopened.moodScore, 3);
    });
    test('latest measurement ignores newer mood-only and future check-ins; CSV leaves blanks', () async {
      final measuredAt = DateTime.now().subtract(const Duration(days: 2));
      await repo.addCheckIn(CheckInInput.parse(now: measuredAt, weight: '70'));
      await repo.addCheckIn(CheckInInput.parse(now: DateTime.now(), mood: 3));
      await repo.addCheckIn(CheckInInput.parse(now: DateTime.now().add(const Duration(days: 1)), weight: '72'));
      expect(await repo.latestMeasurementDate(), measuredAt);
      final service = ExportService(repo, temporaryDirectory: () async => directory);
      final csv = await service.exportCsv(startDate: measuredAt, endDate: DateTime.now(), includeCheckIns: true, includeMeals: false, includeWorkouts: false);
      final text = await csv.readAsString(); expect(text, isNot(contains('null'))); expect(text, contains(',,,,3,'));
      final pdf = await service.exportPdf(startDate: measuredAt, endDate: DateTime.now(), includeCheckIns: true, includeMeals: false, includeWorkouts: false);
      expect(await pdf.length(), greaterThan(0));
    });
  });
}
