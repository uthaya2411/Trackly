import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends Notifier<bool> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  bool build() {
    // Initial check
    Connectivity().checkConnectivity().then((results) {
      state = _isOffline(results);
    });

    // Listen to changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      state = _isOffline(results);
    });

    ref.onDispose(() {
      _subscription.cancel();
    });

    return false; // Assume online initially
  }

  bool _isOffline(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    // connectivity_plus v6 lists all connection types. If it only contains .none, we are offline.
    if (results.length == 1 && results.first == ConnectivityResult.none) {
      return true;
    }
    return false;
  }

  // Trigger manual check (e.g. for Refresh button)
  Future<void> forceCheck() async {
    final results = await Connectivity().checkConnectivity();
    state = _isOffline(results);
  }
}

final isOfflineProvider = NotifierProvider.autoDispose<ConnectivityNotifier, bool>(() {
  return ConnectivityNotifier();
});
