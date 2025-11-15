import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Provides a global notifier for network connectivity.
///
/// The [ConnectivityProvider] listens to changes in the device's network
/// connectivity using the `connectivity_plus` plugin. It exposes a
/// [ValueNotifier<bool>] via [isOffline] that emits `true` when there is
/// no connection. Initialize the provider in `main.dart` before
/// running the app by calling [ConnectivityProvider.instance.initialize()].
class ConnectivityProvider {
  ConnectivityProvider._internal();

  /// Singleton instance.
  static final ConnectivityProvider instance = ConnectivityProvider._internal();

  /// Notifier indicating whether the device is currently offline.
  final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);

  StreamSubscription<ConnectivityResult>? _subscription;

  /// Initialize the connectivity listener.  Performs an initial check
  /// and starts listening for subsequent changes.
  void initialize() {
    _checkConnectivity();
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      _updateStatus(result);
    });
  }

  /// Dispose the connectivity listener.
  void dispose() {
    _subscription?.cancel();
  }

  /// Manually trigger a connectivity check.  Useful for a "Retry"
  /// button when the device is offline.
  Future<void> retry() async {
    await _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(ConnectivityResult result) {
    // Determine offline based on connectivity result.  Treat none as
    // offline; all other types (wifi, mobile, ethernet) as online.
    final offline = result == ConnectivityResult.none;
    if (isOffline.value != offline) {
      isOffline.value = offline;
    }
  }
}