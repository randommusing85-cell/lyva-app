import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/repos/user_profile_repo.dart';
import 'package:lyva_app/services/analytics_service.dart';
import 'package:lyva_app/screens/edit_profile_screen.dart';
import 'package:lyva_app/state/providers.dart';

class MemoryProfileRepo extends UserProfileRepo {
  MemoryProfileRepo(this.profile);
  UserProfile profile;
  UserProfile? saved;
  @override
  Future<UserProfile?> getProfile() async => profile;
  @override
  Future<void> saveProfile(UserProfile value) async {
    saved = value;
    profile = value;
  }
}

class FakeAnalytics extends Fake implements AnalyticsService {
  @override
  Future<void> logProfileUpdated({required List<String> fieldsChanged}) async {}
}

void main() {
  testWidgets('editing weight preserves unrelated and freshly updated fields', (
    tester,
  ) async {
    final profile = UserProfile()
      ..id = 1
      ..name = 'Alex'
      ..age = 30
      ..sex = 'female'
      ..heightCm = 165
      ..weightKg = 60
      ..goal = 'recomp'
      ..level = 'beginner'
      ..equipment = 'gym'
      ..trainingDaysPerWeek = 3
      ..scheduledDaysList = [1, 3, 5]
      ..createdAt = DateTime(2026)
      ..updatedAt = DateTime(2026)
      ..injuryList = ['knee_left']
      ..injuryNotes = 'Keep this note'
      ..notifyCheckIn = false
      ..notifyWorkout = false
      ..notifyCycle = false
      ..reminderHour = 17
      ..reminderMinute = 25
      ..isPremium = true
      ..premiumTier = 'premium'
      ..premiumTrialStart = DateTime(2026)
      ..usageResetDate = DateTime(2026)
      ..aiCoachMessagesUsed = 9
      ..photoAnalysesUsed = 2;
    final repo = MemoryProfileRepo(profile);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (_) async => 'Asia/Singapore',
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => call.method == 'initialize' ? true : null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepoProvider.overrideWithValue(repo),
          analyticsProvider.overrideWithValue(FakeAnalytics()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfileScreen(),
                ),
              ),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    // Simulate an unrelated update after the editor loaded its snapshot.
    repo.profile = profile..aiCoachMessagesUsed = 10;
    final weight = find.byWidgetPredicate(
      (w) => w is TextFormField && w.controller?.text == '60.0',
    );
    expect(weight, findsOneWidget);
    await tester.enterText(weight, '61.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = repo.saved!;
    expect(saved.weightKg, 61.5);
    expect(saved.name, 'Alex');
    expect(saved.injuryList, ['knee_left']);
    expect(saved.injuryNotes, 'Keep this note');
    expect(saved.notifyCheckIn, isFalse);
    expect(saved.notifyWorkout, isFalse);
    expect(saved.notifyCycle, isFalse);
    expect(saved.reminderHour, 17);
    expect(saved.reminderMinute, 25);
    expect(saved.isPremium, isTrue);
    expect(saved.premiumTier, 'premium');
    expect(saved.premiumTrialStart, DateTime(2026));
    expect(saved.usageResetDate, DateTime(2026));
    expect(saved.aiCoachMessagesUsed, 10);
    expect(saved.photoAnalysesUsed, 2);
  });
}
