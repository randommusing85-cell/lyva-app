import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/coach_message.dart';
import 'package:lyva_app/models/progress_photo.dart';
import 'package:lyva_app/models/ai_insight.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/repos/lyva_repo.dart';

void main() {
  late Directory directory;
  late Isar database;
  late LyvaRepo repo;
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
    directory = await Directory.systemTemp.createTemp('lyva_integrity_test_');
    database = await Isar.open(
      [
        CoachMessageSchema,
        ProgressPhotoSchema,
        AiInsightSchema,
        WorkoutTemplateDocSchema,
      ],
      directory: directory.path,
      name: 'test',
      inspector: false,
    );
    repo = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () async => database);
  });
  tearDown(() async {
    await database.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });
  CoachMessage message(String role) => CoachMessage()
    ..ts = DateTime(2026)
    ..role = role
    ..content = role
    ..isLoading = role == 'assistant';

  test(
    'workout persistence validates legacy JSON and survives a database restart',
    () async {
      final doc = WorkoutTemplateDoc()
        ..createdAt = DateTime(2026)
        ..planName = 'Custom'
        ..level = 'custom'
        ..equipment = 'mixed'
        ..daysPerWeek = 1
        ..sex = 'any'
        ..isCustom = true
        ..json = jsonEncode({
          'days': [
            {
              'dayName': 'Legs',
              'exercises': [
                {'name': 'Squat', 'sets': 4, 'reps': '8', 'rest': '120s'},
              ],
            },
          ],
        });
      await repo.saveWorkoutTemplate(doc);
      await database.close();
      database = await Isar.open(
        [
          CoachMessageSchema,
          ProgressPhotoSchema,
          AiInsightSchema,
          WorkoutTemplateDocSchema,
        ],
        directory: directory.path,
        name: 'test',
        inspector: false,
      );
      final saved = await repo.getLatestWorkoutTemplate();
      final exercise = jsonDecode(saved!.json)['days'][0]['exercises'][0];
      expect(exercise['workingSets'], 4);
      expect(exercise['restSeconds'], 120);
      expect(exercise['exerciseId'], isNotEmpty);
      doc.json = '{"days":[]}';
      await expectLater(repo.saveWorkoutTemplate(doc), throwsFormatException);
      expect((await repo.getLatestWorkoutTemplate())!.json, saved.json);
    },
  );

  test(
    'photo deleted while analysis awaits response is never recreated',
    () async {
      final photo = ProgressPhoto()
        ..ts = DateTime(2026)
        ..imagePath = 'fixture-only';
      await repo.saveProgressPhoto(photo);
      final operation = repo.beginPhotoAnalysis(photo.id);
      final response = Completer<String>();
      final completion = response.future.then(
        (value) => repo.completePhotoAnalysis(photo.id, operation, value),
      );
      await repo.deleteProgressPhoto(photo.id);
      response.complete('{"result":"late"}');
      expect(await completion, isFalse);
      expect(await repo.getAllProgressPhotos(), isEmpty);
    },
  );
  test(
    'new photo analysis supersedes older retry; completion before deletion is removed',
    () async {
      final photo = ProgressPhoto()
        ..ts = DateTime(2026)
        ..imagePath = 'fixture-only';
      await repo.saveProgressPhoto(photo);
      final old = repo.beginPhotoAnalysis(photo.id);
      final current = repo.beginPhotoAnalysis(photo.id);
      expect(await repo.completePhotoAnalysis(photo.id, old, 'old'), isFalse);
      expect(
        await repo.completePhotoAnalysis(photo.id, current, 'new'),
        isTrue,
      );
      expect((await repo.getAllProgressPhotos()).single.analysisJson, 'new');
      await repo.deleteProgressPhoto(photo.id);
      expect(await repo.getAllProgressPhotos(), isEmpty);
    },
  );
  for (final fails in [false, true]) {
    test(
      'Clear Chat rejects delayed ${fails ? 'error' : 'success'} and permits a fresh turn',
      () async {
        final generation = repo.chatGeneration;
        final assistant = message('assistant');
        expect(
          await repo.beginCoachTurn(message('user'), assistant, generation),
          isTrue,
        );
        final response = Completer<String>();
        final pending = () async {
          try {
            assistant.content = await response.future;
          } catch (_) {
            assistant.content = 'Please try again';
          }
          assistant.isLoading = false;
          return repo.completeCoachTurn(assistant, generation);
        }();
        await repo.clearCoachMessages();
        final fresh = message('assistant');
        await repo.beginCoachTurn(message('user'), fresh, repo.chatGeneration);
        if (fails) {
          response.completeError(StateError('offline'));
        } else {
          response.complete('late');
        }
        expect(await pending, isFalse);
        expect((await repo.getRecentCoachMessages()).length, 2);
        fresh
          ..content = 'current'
          ..isLoading = false;
        expect(
          await repo.completeCoachTurn(fresh, repo.chatGeneration),
          isTrue,
        );
      },
    );
  }
  test(
    'Clear Chat invalidates work before database access and rejects pending inserts and insights',
    () async {
      final gate = Completer<Isar>();
      final delayed = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () => gate.future);
      final generation = delayed.chatGeneration;
      final insert = delayed.beginCoachTurn(
        message('user'),
        message('assistant'),
        generation,
      );
      final clear = delayed.clearCoachMessages();
      gate.complete(database);
      expect(await insert, isFalse);
      await clear;
      await delayed.saveChatInsights([
        AiInsight()
          ..ts = DateTime(2026)
          ..category = 'test'
          ..content = 'late'
          ..confidence = 1,
      ], generation);
      expect(await delayed.getRecentCoachMessages(), isEmpty);
      expect(await delayed.getActiveInsights(), isEmpty);
    },
  );
  test(
    'navigation does not matter to a valid repository completion; duplicate completion is rejected',
    () async {
      final assistant = message('assistant');
      final generation = repo.chatGeneration;
      await repo.beginCoachTurn(message('user'), assistant, generation);
      assistant
        ..content = 'done'
        ..isLoading = false;
      expect(await repo.completeCoachTurn(assistant, generation), isTrue);
      assistant.content = 'late error';
      expect(await repo.completeCoachTurn(assistant, generation), isFalse);
      expect(
        (await repo.getRecentCoachMessages())
            .where((m) => m.role == 'assistant')
            .single
            .content,
        'done',
      );
    },
  );
}
