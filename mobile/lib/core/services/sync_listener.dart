import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';

class SyncListener {
  final connectivity = ConnectivityService();
  final syncService = SyncService();

  void start() {
    connectivity.onConnectivityChanged.listen((results) {
      final hasInternet = !results.contains(ConnectivityResult.none);

      if (hasInternet) {
        print("🌐 Internet back → syncing...");
        syncService.syncUser();
      }
    });
  }
}