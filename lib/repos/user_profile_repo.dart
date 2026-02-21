import 'package:isar/isar.dart';
import 'package:primeform_app/db/isar_db.dart';
import 'package:primeform_app/models/user_profile.dart';

class UserProfileRepo {
  /// Get the user profile (there should only be one)
  Future<UserProfile?> getProfile() async {
    final isar = await IsarDb.instance();
    return isar.userProfiles.where().findFirst();
  }
  
  /// Watch active injuries (reactive stream)
  Stream<List<String>> watchActiveInjuries() async* {
    final isar = await IsarDb.instance();
    yield* isar.userProfiles
        .where()
        .watch(fireImmediately: true)
        .map((profiles) => profiles.firstOrNull?.injuryList ?? <String>[]);
  }
  
  /// Save or update the user profile
  Future<void> saveProfile(UserProfile profile) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.userProfiles.put(profile);
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

  /// Delete the user profile (for testing/reset)
  Future<void> deleteProfile() async {
    final isar = await IsarDb.instance();
    final profile = await getProfile();
    if (profile == null) return;
    
    await isar.writeTxn(() async {
      await isar.userProfiles.delete(profile.id);
    });
  }
}