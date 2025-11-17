import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

/// Page to initiate the password reset process. The user enters
/// their email address and, on submission, a reset code is sent.
/// After the code is sent the user is navigated to the reset
/// password screen with the email passed as an argument.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passwort vergessen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bitte geben Sie Ihre E‑Mail ein. Wir senden Ihnen einen Code zum Zurücksetzen Ihres Passworts.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E‑Mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final email = _emailController.text.trim();
                      if (email.isEmpty ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bitte geben Sie eine gültige E‑Mail ein.'),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _loading = true;
                      });
                      try {
                        await AuthService.sendPasswordResetEmail(email);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code gesendet. Bitte prüfen Sie Ihre E‑Mail.'),
                          ),
                        );
                        Navigator.of(context).pushNamed(
                          '/reset-password',
                          arguments: {'email': email},
                        );
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Senden des Codes: $error'),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _loading = false;
                          });
                        }
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Code senden'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Zurück zum Login'),
            ),
          ],
        ),
      ),
    );
  }
}
