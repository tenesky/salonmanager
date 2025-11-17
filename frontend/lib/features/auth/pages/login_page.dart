import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../common/themed_background.dart';

/// A simple login screen with email and password fields.
/// Shows inline validation and a hint that 2FA will follow.
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  // Track whether the password should be obscured.  Toggled via the eye icon.
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the login process and ensures that the user is always
  /// forwarded to the 2FA page after a successful credential check,
  /// even if sending the OTP fails. This avoids scenarios where
  /// valid credentials result in no navigation due to an OTP error.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _loading = true;
    });
    try {
      // First sign in with email and password. This will throw if
      // the credentials are invalid.
      await AuthService.signInWithPassword(email: email, password: password);
      // Attempt to send a one‑time code for two‑factor authentication.
      bool otpSent = false;
      try {
        await AuthService.sendOtpForExistingUser(email);
        otpSent = true;
      } catch (_) {
        // Ignore OTP errors here; we'll still navigate to the code page.
      }
      if (!mounted) return;
      if (otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code gesendet. Bitte prüfen Sie Ihre E‑Mail.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Anmeldung erfolgreich. Falls kein Code ankommt, bitte erneut senden.')),
        );
      }
      Navigator.of(context).pushNamed('/two-factor', arguments: {
        'email': email,
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Login: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    final brightness = Theme.of(context).brightness;
    // Use a dark patterned background with a semi‑transparent overlay to
    // match the design shown in the provided mockups.
    return Scaffold(
      // Remove the default app bar for a full‑screen experience.
      body: ThemedBackground(
        child: Container(
          // Ensure the colour overlay covers the entire screen so the patterned
          // background remains visible even below the scrollable content. Use
          // full width and height instead of relying on the child to size the
          // container; this avoids leaving a plain black area at the bottom.
          width: double.infinity,
          height: double.infinity,
          // Overlay a translucent colour on top of the patterned background.
          // Use a slightly lower opacity to allow more of the pattern
          // to shine through. Dark mode uses black with 40% opacity; light
          // mode uses white with 40% opacity.
          color: brightness == Brightness.dark
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.4),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    // Welcome headline: "Willkommen! Bei SalonManager"
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Willkommen!\n',
                            style: TextStyle(
                              color: brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Bei\n',
                            style: TextStyle(
                              color: brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: 'SalonManager',
                            style: TextStyle(
                              color: accent,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Email input
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                        filled: true,
                        fillColor: brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: accent,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte E‑Mail eingeben';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Ungültige E‑Mail‑Adresse';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password input with toggle visibility icon
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                        filled: true,
                        fillColor: brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: accent,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Passwort eingeben';
                        }
                        if (value.length < 6) {
                          return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                        }
                        return null;
                      },
                    ),
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/forgot-password');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Registration prompts
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Not a member? ',
                              style: TextStyle(
                                color: brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed('/register-customer');
                              },
                              child: Text(
                                'Register now',
                                style: TextStyle(
                                  // Highlight the call‑to‑action in the accent
                                  // colour (gold/yellow) instead of black/white
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Du bist Inhaber eines Salons? ',
                              style: TextStyle(
                                color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/register-salon');
                              },
                              child: Text(
                                'Hier Registrieren',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}