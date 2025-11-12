import 'package:supabase_flutter/supabase_flutter.dart';

/// A service that wraps Supabase authentication.  It replaces the
/// earlier REST‑based backend with Supabase's email OTP login
/// mechanism.  Once initialized in main.dart, the Supabase client
/// handles session persistence automatically.  Roles and profile
/// information can be managed via the `profiles` table as shown in
/// the migration SQL.  For development we limit this service to
/// sending and verifying OTP codes and checking the login state.
class AuthService {
  // Singleton instance to ensure a single Supabase client is reused.
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Supabase client shortcut
  final SupabaseClient _client = Supabase.instance.client;

  /// Send a one‑time password to the given [email].  This will
  /// initiate a new sign‑in flow or create the user if they don't
  /// already exist.  Supabase sends a 6‑digit code to the address
  /// configured in your project (via the custom SMTP settings).  No
  /// password is required.
  Future<void> sendOtp({required String email}) async {
    await _client.auth.signInWithOtp(email: email);
  }

  /// Verify the OTP [code] for the given [email].  Returns true if
  /// the verification succeeds and a session is established.  On
  /// failure an exception is thrown.  After successful verification
  /// the session is stored automatically and can be accessed via
  /// [_client.auth.currentSession].
  Future<bool> verifyOtp({required String email, required String code}) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    return response.session != null;
  }

  /// Determine whether a user is currently logged in.  Returns true
  /// when a valid session exists.
  bool get isLoggedIn => _client.auth.currentSession != null;

  /// Sign the user out and clear the local session.
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}