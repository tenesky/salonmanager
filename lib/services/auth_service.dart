import 'package:supabase_flutter/supabase_flutter.dart';

/// A service that wraps Supabase authentication flows. Provides helper
/// methods to sign up, sign in, send and verify one‑time passwords (OTP),
/// reset passwords and manage the current session. This service does not
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
    // Explicitly specify the channel as email to ensure Supabase sends a
    // six‑digit code instead of only a magic link. Without setting
    // `channel: OtpChannel.email`, Supabase may default to sending a
    // magic‑link email template which might not include the one‑time code.
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: null,
      channel: OtpChannel.email,
    );
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

  /// Sends a password reset email to the given address. Supabase will send
  /// an email containing a reset code or link. This wrapper simply
  /// forwards the call to Supabase; if an error occurs it will throw an
  /// [AuthException].
  static Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Invites a new user via Supabase Auth.  Only callers with
  /// sufficient privileges (e.g. platform admins or service role
  /// keys) can use this method.  The [email] must belong to the
  /// prospective team member.  Returns the invited user's id on
  /// success, or null if the invite fails.  Throws an exception
  /// for network errors.  Use this in combination with
  /// [DbService.updateSalonMemberRole] after the user accepts the
  /// invitation.
  static Future<String?> inviteUser(String email) async {
    try {
      final admin = _client.auth.admin;
      // The inviteUserByEmail method in supabase_flutter v2.x expects
      // the email as a positional argument and returns an AdminUserResponse.
      final response = await admin.inviteUserByEmail(email);
      final user = response.user;
      return user?.id;
    } on AuthException catch (e) {
      throw e;
    }
  }

  /// Verifies a recovery OTP code and updates the user's password. Returns
  /// true on success. When the recovery code is verified Supabase will
  /// establish a temporary session which allows updating the user's
  /// password via [updateUser]. If verification or the update fails,
  /// an exception will be thrown or false will be returned.
  static Future<bool> verifyRecoveryAndUpdatePassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
    if (response.session == null) {
      return false;
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    return true;
  }
}
