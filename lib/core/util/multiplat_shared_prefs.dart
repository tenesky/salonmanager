import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MultiplatSharedPrefs {
  static final bool _useFileSystem =
      !kIsWeb && (Platform.isWindows || Platform.isLinux);

  static const String _selected_index_key = "selectedIndex";
  static const _prefsFile = 'multiplat_sharedprefs.txt';
  static String _prefsFullPath = '';

  // Keys for storing auth token and user role. These values are saved
  // using SharedPreferences on all platforms except Windows/Linux desktop,
  // where this app writes to a temporary file for a single integer. For
  // authentication we only support SharedPreferences.
  static const String _tokenKey = 'authToken';
  static const String _roleKey = 'userRole';
  // Key for storing the current logged in user ID. This allows the
  // application to identify the user (customer, employee or admin) when
  // making subsequent API calls, such as booking an appointment. The
  // backend returns the userId in the login response and we persist it
  // here in SharedPreferences on all platforms.
  static const String _userIdKey = 'userId';

  Future<int> getSelectedItemIndex() async {
    if (_useFileSystem) {
      return _readFile();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_selected_index_key) ?? 0;
  }

  Future<bool> setSelectedItemIndex(int index) async {
    if (_useFileSystem) {
      return _writeFile(index);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setInt(_selected_index_key, index);
  }

  Future<int> _readFile() async {
    try {
      final file = File(_getFullPath());
      if (file.existsSync()) {
        final str = file.readAsStringSync();
        if (str.isNotEmpty) {
          return int.parse(str);
        }
      }
    } catch (e, s) {
      print('Error occurred trying to read $_prefsFile: $e');
      print('$s');
      // swallow error
    }
    return 0;
  }

  Future<bool> _writeFile(int selectedIndex) async {
    try {
      File(_getFullPath()).writeAsStringSync('$selectedIndex');
    } catch (e, s) {
      print('Error occurred trying to write to $_prefsFile: $e');
      print('$s');
      return false;
      // swallow error
    }
    return true;
  }

  /// Saves a JWT or session token returned by the API. Uses
  /// SharedPreferences across all platforms. Returns true on success.
  Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_tokenKey, token);
  }

  /// Retrieves the stored authentication token, or null if none is stored.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Saves the role of the currently authenticated user (customer, employee, admin).
  Future<bool> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_roleKey, role);
  }

  /// Retrieves the stored user role, or null if none is stored.
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Saves the userId of the currently authenticated user. The userId
  /// originates from the backend login response. Returns true on
  /// success.
  Future<bool> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userIdKey, userId);
  }

  /// Retrieves the stored userId, or null if none is stored. Useful
  /// when creating bookings or performing operations that require
  /// identifying the current user.
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  String _getFullPath() {
    _prefsFullPath = Directory.systemTemp.path +
        (Platform.isWindows ? '\\' : '/') +
        _prefsFile;
    print('shared prefs file is $_prefsFullPath');
    return _prefsFullPath;
  }
}
