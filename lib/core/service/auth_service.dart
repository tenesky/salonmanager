import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:multiplat/core/util/multiplat_shared_prefs.dart';
import 'package:multiplat/locator.dart';

/// Service responsible for making authentication requests to the backend API.
/// It provides methods for logging in and registering users. The base URL
/// should be adjusted to point at your PHP API endpoint.
class AuthService {
  // Base URL of the PHP API. Adjust this to match your deployment.
  final String baseUrl = 'https://api-4people.3g-hosting.de';

  /// Logs a user in with the given [email], [password] and [role]. Returns
  /// `true` if successful, otherwise `false`. On success, user data can be
  /// stored locally via SharedPreferences.
  Future<bool> login(String email, String password, String role) async {
    final uri = Uri.parse('$baseUrl/login.php');
    try {
      final response = await http.post(uri, body: {
        'email': email,
        'password': password,
        'role': role,
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['success'] == true) {
          // Optionally save token or user details to SharedPreferences
          final prefs = locator<MultiplatSharedPrefs>();
          await prefs.saveToken(decoded['token'] ?? '');
          await prefs.saveRole(role);
          // Persist the userId so the app can reference the current user in
          // later operations (e.g. creating bookings). The login
          // response includes userId as a string or integer.
          final userId = decoded['userId'];
          if (userId != null) {
            await prefs.saveUserId(userId.toString());
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Registers a new user with [name], [email], [password] and [role]. Returns
  /// `true` if successful, otherwise `false`.
  Future<bool> register(
      String name, String email, String password, String role) async {
    final uri = Uri.parse('$baseUrl/register.php');
    try {
      final response = await http.post(uri, body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is Map && decoded['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}