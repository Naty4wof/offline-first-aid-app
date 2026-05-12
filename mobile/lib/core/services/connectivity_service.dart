import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// ✅ Check current connection
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();

    // result is List<ConnectivityResult>
    return !result.contains(ConnectivityResult.none);
  }

  /// ✅ Stream of connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}