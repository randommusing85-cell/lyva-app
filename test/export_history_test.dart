import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/meal_log.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/services/export_service.dart';

void main() {
  late Directory directory;
  late Isar database;
  late LyvaRepo repo;
  Future<Isar> open() => Isar.open(
    [WorkoutSessionDocSchema, MealLogSchema, CheckInSchema],
    directory: directory.path,
    name: 'history',
    inspector: false,
  );
  setUpAll(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.windowsX64: File(
          'vendor/isar_flutter_libs/windows/isar.dll',
        ).absolute.path,
        Abi.linuxX64: File(
          'vendor/isar_flutter_libs/linux/libisar.so',
        ).absolute.path,
        Abi.macosX64: File(
          'vendor/isar_flutter_libs/macos/libisar.dylib',
        ).absolute.path,
        Abi.macosArm64: File(
          'vendor/isar_flutter_libs/macos/libisar.dylib',
        ).absolute.path,
      },
    );
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('lyva_history_');
    database = await open();
    repo = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () async => database);
  });
  tearDown(() async {
    if (database.isOpen) await database.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });

  ExportService service() => ExportService(
    repo,
    temporaryDirectory: () async => directory,
    documentFactory: () => pw.Document(compress: false),
  );
  Future<void> seed() async {
    await database.writeTxn(() async {
      for (var day = 1; day <= 3; day++) {
        await database.workoutSessionDocs.put(
          WorkoutSessionDoc()
            ..date = DateTime(2020, 2, day, 12)
            ..dayIndex = day
            ..completed = day == 1
            ..skipped = day == 2
            ..skipReason = day == 2 ? 'Rest' : null
            ..notes = 'Historical $day',
        );
        await database.mealLogs.put(
          MealLog()
            ..ts = DateTime(2020, 2, day, 12)
            ..mealType = 'lunch'
            ..proteinG = 10
            ..carbsG = 20
            ..fatG = 5
            ..description = 'Old meal $day',
        );
      }
      await database.mealLogs.put(
        MealLog()
          ..ts = DateTime.now()
          ..mealType = 'snack'
          ..proteinG = 1
          ..carbsG = 2
          ..fatG = 3
          ..description = 'Recent meal',
      );
    });
  }

  test(
    'CSV preserves one-based historical days and exact historical meal interval',
    () async {
      await seed();
      final file = await service().exportCsv(
        startDate: DateTime(2020, 2, 1, 12),
        endDate: DateTime(2020, 2, 2, 12),
        includeCheckIns: false,
        includeMeals: true,
        includeWorkouts: true,
      );
      final csv = await file.readAsString();
      expect(csv, contains('2020-02-01,Day 1,Yes,No'));
      expect(csv, contains('2020-02-02,Day 2,No,Yes,Rest'));
      expect(csv, isNot(contains('Day 3')));
      expect(csv, contains('Old meal 1'));
      expect(csv, contains('Old meal 2'));
      expect(csv, isNot(contains('Old meal 3')));
      expect(csv, isNot(contains('Recent meal')));
    },
  );
  test('PDF contains known day labels and historical rows', () async {
    await seed();
    final file = await service().exportPdf(
      startDate: DateTime(2020, 2, 1),
      endDate: DateTime(2020, 2, 4),
      includeCheckIns: false,
      includeMeals: true,
      includeWorkouts: true,
    );
    final pdf = latin1.decode(await file.readAsBytes());
    expect(pdf, startsWith('%PDF-'));
    // The PDF writer emits separate text-show operators for individual words.
    // Extract only the ASCII fixture's text runs; this is not a general PDF parser.
    final text = RegExp(r'\[\(([^)]*)\)\]TJ').allMatches(pdf)
        .map((match) => match.group(1)!).join(' ');
    expect(text, contains('Day 1')); expect(text, contains('Day 2'));
    expect(text, contains('Day 3')); expect(text, isNot(contains('Day 4')));
    expect(text, contains('Historical 1'));
    expect(text, contains('Meal History'));

  });
  test(
    'UTC boundary timestamps export on local calendar date consistently',
    () async {
      final instant = DateTime.parse('2020-02-29T23:30:00-05:00');
      await database.writeTxn(() async {
        await database.workoutSessionDocs.put(
          WorkoutSessionDoc()
            ..date = instant
            ..dayIndex = 1
            ..completed = true,
        );
      });
      final file = await service().exportCsv(
        startDate: instant,
        endDate: instant,
        includeCheckIns: false,
        includeMeals: false,
        includeWorkouts: true,
      );
      expect(
        await file.readAsString(),
        contains('${DateFormat('yyyy-MM-dd').format(instant.toLocal())},Day 1'),
      );
    },
  );
  test(
    'unknown legacy day is not silently renumbered; empty and reversed ranges',
    () async {
      expect(
        ExportService.workoutDayLabel(WorkoutSessionDoc()..dayIndex = 0),
        'Unknown day',
      );
      final file = await service().exportCsv(
        startDate: DateTime(2000),
        endDate: DateTime(2001),
        includeCheckIns: false,
        includeMeals: false,
        includeWorkouts: true,
      );
      expect(await file.readAsString(), contains('Date,Day,Completed'));
      await expectLater(
        service().exportPdf(
          startDate: DateTime(2001),
          endDate: DateTime(2000),
          includeCheckIns: false,
          includeMeals: false,
          includeWorkouts: true,
        ),
        throwsArgumentError,
      );
    },
  );
}
