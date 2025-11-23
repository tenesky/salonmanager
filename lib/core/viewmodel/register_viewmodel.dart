import 'package:flutter/material.dart';
import 'package:multiplat/core/service/auth_service.dart';
import 'package:multiplat/locator.dart';

/// ViewModel responsible for handling user registration. Provides loading
/// and error states to the UI and delegates registration calls to
/// [AuthService].
class RegisterViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<bool> register(
      String name, String email, String password, String role) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final authService = locator<AuthService>();
      final success =
          await authService.register(name, email, password, role);
      if (!success) {
        _error = 'Registrierung fehlgeschlagen';
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