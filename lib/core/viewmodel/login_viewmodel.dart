import 'package:flutter/material.dart';
import 'package:multiplat/core/service/auth_service.dart';
import 'package:multiplat/locator.dart';

/// ViewModel responsible for handling login interactions. It exposes
/// loading and error states and delegates the actual login call to
/// [AuthService].
class LoginViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<bool> login(String email, String password, String role) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final authService = locator<AuthService>();
      final success = await authService.login(email, password, role);
      if (!success) {
        _error = 'Login fehlgeschlagen';
      }
      return success;
    } catch (e) {
      _error = 'Ein unerwarteter Fehler ist aufgetreten';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}