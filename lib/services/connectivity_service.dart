import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton service that listens to connectivity changes.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> init() async {
    // Initial check
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.0+ returns a List<ConnectivityResult>
    // If list contains 'none', we are offline. 
    // Otherwise, if it has wifi, mobile, etc., we're online.
    final bool hasConnection = results.any((result) => result != ConnectivityResult.none);
    
    if (isConnected.value != hasConnection) {
      isConnected.value = hasConnection;
      debugPrint('[CONNECTIVITY] Status changed: ${hasConnection ? "ONLINE" : "OFFLINE"}');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
