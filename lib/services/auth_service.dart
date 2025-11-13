import 'package:supabase_flutter/supabase_flutter.dart';

/// A service that wraps Supabase authentication flows. Provides helper
/// methods to sign in with an email-based one‑time password (OTP), verify
/// the OTP and manage the current session. This service does not
/// persist any additional state; all user/session state is stored in
/// Supabase's internal cache.
class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Registers a new user account using email and password. This creates
  /// the user in Supabase Auth and triggers a confirmation email if
  /// confirmation is required by your project settings. If registration
  /// fails (e.g. the email is already taken), an [AuthException] is
  /// thrown. After a successful sign‑up you should send an OTP via
  /// [sendOtpForExistingUser] to perform 2FA.
  static Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email, password: password);
  }

  /// Signs in an existing user using their email and password. This
  /// method verifies the credentials and returns an [AuthResponse]
  /// containing a session on success. If authentication fails, a
  /// [AuthException] is thrown. After a successful password login you
  /// should call [sendOtpForExistingUser] to initiate the second
  /// authentication factor.
  static Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sends a one‑time password (OTP) email to an existing user. This
  /// triggers Supabase to send an email containing a 6‑digit code. The
  /// parameter `shouldCreateUser` is set to `false` to ensure a new user
  /// record is not created when sending the OTP after sign‑up or sign‑in.
  static Future<void> sendOtpForExistingUser(String email) async {
    await _client.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  /// Verifies a one‑time password for the given email address. Returns
  /// true if the verification succeeds and a session is established.
  /// Otherwise throws an exception or returns false. The [type]
  /// parameter is set to [OtpType.email] because we are using email
  /// codes. For phone number codes, use [OtpType.sms].
  static Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: code,
    );
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