import 'package:offline_first_aid_app/core/services/storage_service.dart';
import 'package:offline_first_aid_app/core/services/connectivity_service.dart';
import 'package:offline_first_aid_app/features/user/user_service.dart';

class SyncService {
  final storage = StorageService.instance;
  final remote = UserService();
  final connectivity = ConnectivityService();

  Future<void> syncUser() async {
    // 🔌 Check internet first
    final isOnline = await connectivity.isConnected();

    if (!isOnline) {
      print("📴 No internet → skip sync");
      return;
    }

    final profile = storage.getUserProfile();

    if (profile == null) return;
    if (profile['isSynced'] == true) return;

    try {
      // ✅ IMPORTANT: send updated version
      final remoteProfile = Map<String, dynamic>.from(profile);
      remoteProfile['isSynced'] = true;

      await remote
          .syncUserProfile(remoteProfile)
          .timeout(const Duration(seconds: 5));

      // ✅ Update local after success
      profile['isSynced'] = true;
      await storage.saveUserProfile(profile);

      print("✅ User synced successfully");
    } catch (e) {
      print("❌ Sync failed (offline or timeout): $e");
    }
  }
}