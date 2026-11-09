import 'package:isar/isar.dart';
import 'package:lyva_app/db/isar_db.dart';
import 'package:lyva_app/models/user_profile.dart';

class UserProfileRepo {
  UserProfileRepo({Future<Isar> Function()? openDatabase})
      : _openDatabase = openDatabase ?? IsarDb.instance;
  final Future<Isar> Function() _openDatabase;
  static final _loadedRevision = Expando<DateTime>('profile revision');

  Stream<UserProfile?> watchProfile() async* {
    final isar = await _openDatabase();
    yield* isar.userProfiles.where().watch(fireImmediately: true).map((rows) => rows.firstOrNull);
  }

  /// Get the user profile (there should only be one)
  Future<UserProfile?> getProfile() async {
    final isar = await _openDatabase();
    final profile = await isar.userProfiles.where().findFirst();
    if (profile != null) _loadedRevision[profile] = profile.updatedAt;
    return profile;
  }
  
  /// Watch active injuries (reactive stream)
  Stream<List<String>> watchActiveInjuries() async* {
    final isar = await _openDatabase();
    yield* isar.userProfiles
        .where()
        .watch(fireImmediately: true)
        .map((profiles) => profiles.firstOrNull?.injuryList ?? <String>[]);
  }
  
  /// Save or update the user profile
  Future<void> saveProfile(UserProfile profile) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      final current = await isar.userProfiles.where().findFirst();
      final expected = _loadedRevision[profile];
      if ((current != null && (expected == null || current.id != profile.id || current.updatedAt != expected)) ||
          (current == null && expected != null)) {
        throw StateError('Profile changed or was removed. Reload before saving.');
      }
      final now = DateTime.now();
      profile.updatedAt = current != null && !now.isAfter(current.updatedAt)
          ? current.updatedAt.add(const Duration(microseconds: 1)) : now;
      await isar.userProfiles.put(profile);
      _loadedRevision[profile] = profile.updatedAt;
    });
  }
  
  /// Check if a profile exists
  Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile != null;
  }
  
  /// Start the 7-day premium trial
  Future<void> startPremiumTrial() async {
    final profile = await getProfile();
    if (profile == null) return;
    if (profile.premiumTrialStart != null) return; // Already started
    profile.premiumTrialStart = DateTime.now();
    profile.updatedAt = DateTime.now();
    await saveProfile(profile);
  }

  /// Update premium subscription tier (called after RevenueCat purchase/restore)
  Future<void> updatePremiumTier(String? tierName) async {
    final profile = await getProfile();
    if (profile == null) return;
    profile.isPremium = tierName != null;
    profile.premiumTier = tierName;
    profile.updatedAt = DateTime.now();
    await saveProfile(profile);
  }

  /// Increment AI coach message usage counter
  Future<void> incrementCoachMessageUsage() async {
    final profile = await getProfile();
    if (profile == null) return;
    profile.aiCoachMessagesUsed += 1;
    profile.updatedAt = DateTime.now();
    await saveProfile(profile);
  }

  /// Increment photo analysis usage counter
  Future<void> incrementPhotoAnalysisUsage() async {
    final profile = await getProfile();
    if (profile == null) return;
    profile.photoAnalysesUsed += 1;
    profile.updatedAt = DateTime.now();
    await saveProfile(profile);
  }

  /// Reset monthly usage counters (called on app open when new month detected)
  Future<void> resetMonthlyUsage() async {
    final profile = await getProfile();
    if (profile == null) return;
    final now = DateTime.now();
    profile.aiCoachMessagesUsed = 0;
    profile.photoAnalysesUsed = 0;
    profile.usageResetDate = DateTime(now.year, now.month, 1);
    profile.updatedAt = DateTime.now();
    await saveProfile(profile);
  }

  /// Delete the user profile (for testing/reset)
  Future<void> deleteProfile() async {
    final isar = await _openDatabase();
    final profile = await getProfile();
    if (profile == null) return;
    
    await isar.writeTxn(() async {
      await isar.userProfiles.delete(profile.id);
    });
  }
}