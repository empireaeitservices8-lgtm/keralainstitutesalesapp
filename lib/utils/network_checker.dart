import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  static final NetworkChecker instance = NetworkChecker._internal();
  NetworkChecker._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if internet is available
  Future<bool> hasConnection() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Listen to connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;
}
