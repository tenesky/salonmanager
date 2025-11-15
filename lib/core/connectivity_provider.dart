import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// A simple provider to track network connectivity status across the app.
///
/// This class exposes a [ValueNotifier] that notifies listeners when the
/// device goes offline or comes back online.  It listens to updates from
/// [Connectivity] and performs an initial check at startup.  Call
/// [ConnectivityProvider.instance.initialize()] early (e.g. in
/// `main.dart`) to start listening.  The [retry] method allows
/// consumers to perform a manual connectivity check (e.g. when the user
/// taps a retry button on the offline page).
class ConnectivityProvider {
  ConnectivityProvider._internal();

  static final ConnectivityProvider instance = ConnectivityProvider._internal();

  /// Notifier that is true when the device is offline.
  final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);

  StreamSubscription<ConnectivityResult>? _subscription;

  /// Initialize the provider.  Start listening for connectivity changes
  /// and update the [isOffline] flag accordingly.  This should be called
  /// once, typically in `main.dart` before running the app.
  void initialize() {
    // Perform an initial check.
    _checkConnectivity();
    // Listen for subsequent connectivity changes.
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      _updateStatus(result);
    });
  }

  /// Manually dispose of the connectivity subscription.  Not strictly
  /// necessary as the listener lives for the lifetime of the app.
  void dispose() {
    _subscription?.cancel();
  }

  /// Trigger a manual connectivity check.  Use this method from the
  /// offline page's retry button to see if the connection has been
  /// restored.  It updates [isOffline] accordingly.
  Future<void> retry() async {
    await _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(ConnectivityResult result) {
    // Consider the device offline if there is no connectivity or only
    // Bluetooth connectivity.  For the purposes of this app we treat
    // mobile and wifi connections as online.
    final offline = result == ConnectivityResult.none;
    if (isOffline.value != offline) {
      isOffline.value = offline;
    }
  }
}