import 'package:supabase_flutter/supabase_flutter.dart';

/// A service that wraps Supabase authentication flows. Provides helper
/// methods to sign in with an email-based one‑time password (OTP), verify
/// the OTP and manage the current session. This service does not
/// persist any additional state; all user/session state is stored in
/// Supabase's internal cache.
class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Sends a one‑time password (OTP) to the given email address. This
  /// triggers Supabase to send an email with a 6‑digit code. The code
  /// can then be verified via [verifyOtp]. Throws an exception if the
  /// request fails.
  static Future<void> sendOtp(String email) async {
    final response = await _client.auth.signInWithOtp(email: email);
    final error = response.error;
    if (error != null) {
      throw error;
    }
  }

  /// Verifies a one‑time password for the given email address. Returns
  /// true if the verification succeeds and a session is established.
  /// Otherwise throws an exception or returns false. The [type]
  /// parameter is set to [OtpType.email] because we are using email
  /// codes. For phone number codes, use [OtpType.sms].
  static Future<bool> verifyOtp({required String email, required String code}) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: code,
    );
    final error = response.error;
    if (error != null) {
      throw error;
    }
    return response.session != null;
  }

  /// Returns whether a user is currently logged in. Uses the current
  /// session from Supabase. If there is no session, the user is
  /// considered logged out.
  static bool isLoggedIn() {
    return _client.auth.currentSession != null;
  }

  /// Returns the current user's email address if logged in, otherwise null.
  /// This can be used to display the user's email in the UI (e.g. in an
  /// Account screen) without directly accessing the Supabase client.
  static String? currentUserEmail() {
    return _client.auth.currentUser?.email;
  }

  /// Logs out the current user by revoking the session. Throws an
  /// exception if the sign‑out fails.
  static Future<void> logout() async {
    await _client.auth.signOut();
  }
}