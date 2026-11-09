import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/progress_photo.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/repos/user_profile_repo.dart';
import 'package:lyva_app/screens/progress_photo_detail_screen.dart';
import 'package:lyva_app/services/premium_service.dart';
import 'package:lyva_app/state/providers.dart';

// Screen-level boundary mock; deletion_integrity_test exercises real Isar transactions.
class ControlledPhotoRepo extends LyvaRepo {
  final response = Completer<Map<String, dynamic>>();
  bool exists = true;
  bool requested = false;
  int accepted = 0;
  @override
  Future<Map<String, dynamic>> analyzeProgressPhoto({
    required String base64Image,
    required Map<String, dynamic> userContext,
  }) {
    requested = true;
    return response.future;
  }

  @override
  Future<void> deleteProgressPhoto(Id id) async {
    exists = false;
  }

  @override
  Future<bool> completePhotoAnalysis(
    Id id,
    int operation,
    String analysis,
  ) async {
    if (!exists) return false;
    accepted++;
    return true;
  }

  @override
  Future<void> saveProgressPhoto(ProgressPhoto photo) async {
    throw StateError('Analysis must use guarded completion, never upsert');
  }
}

class PhotoUsage extends UserProfileRepo {
  int used = 0;
  @override
  Future<void> incrementPhotoAnalysisUsage() async {
    used++;
  }
}

class PhotoAccess extends Fake implements PremiumService {
  @override
  Future<PremiumAccessStatus> getAccessStatusAsync(
    UserProfile? profile,
  ) async => PremiumAccessStatus.subscribed(PremiumTier.premium);
}

void main() {
  late Directory directory;
  late ControlledPhotoRepo repo;
  late ProgressPhoto photo;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('lyva_photo_widget_');
    photo = ProgressPhoto()
      ..id = 1
      ..ts = DateTime(2026)
      ..imagePath = '${directory.path}/missing-synthetic-photo.png';
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  for (final action in [
    'delete-success',
    'delete-error',
    'navigate-success',
    'navigate-error',
  ]) {
    testWidgets(
      'photo response after $action respects deletion and navigation',
      (tester) async {
        repo = ControlledPhotoRepo();
        final usage = PhotoUsage();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lyvaRepoProvider.overrideWithValue(repo),
              userProfileRepoProvider.overrideWithValue(usage),
              userProfileProvider.overrideWith((ref) async => null),
              premiumServiceProvider.overrideWithValue(PhotoAccess()),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        settings: RouteSettings(arguments: photo),
                        builder: (_) => ProgressPhotoDetailScreen(
                          readImage: (_) async => [1, 2, 3],
                        ),
                      ),
                    ),
                    child: const Text('Open photo'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open photo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Analyze Photo'));
        await tester.pump();
        await tester.pump();
        expect(repo.requested, isTrue);
        if (action.startsWith('delete')) {
          await tester.tap(find.byIcon(Icons.delete_outline));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.runAsync(() async {
            await tester.tap(find.text('Delete'));
            await Future<void>.delayed(const Duration(milliseconds: 30));
          });
        } else {
          await tester.pageBack();
        }
        if (action.endsWith('error')) {
          repo.response.completeError(StateError('offline'));
        } else {
          repo.response.complete({'encouragement': 'Fixture response'});
        }
        await tester.pumpAndSettle();
        expect(repo.exists, action.startsWith('navigate'));
        expect(repo.accepted, action == 'navigate-success' ? 1 : 0);
        expect(usage.used, action == 'navigate-success' ? 1 : 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
