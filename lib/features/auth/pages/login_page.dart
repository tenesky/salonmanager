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
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: primary,
      ),
      body: ThemedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte E-Mail eingeben';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Ungültige E-Mail-Adresse';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Passwort',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        foregroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Code anfordern'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register-customer');
                    },
                    child: const Text('Neu registrieren'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}