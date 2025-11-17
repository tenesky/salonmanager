import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

/// Page to reset the user's password using a recovery code. The user
/// enters the code they received and their new password. On success,
/// they are redirected to the login page. Errors are surfaced via
/// Snackbars.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _email;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the email passed via route arguments. Only set it once.
    if (_email == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['email'] is String) {
        _email = args['email'] as String;
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passwort zurücksetzen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Geben Sie den Code und Ihr neues Passwort ein.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie den Code ein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Neues Passwort',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte ein neues Passwort eingeben.';
                  }
                  if (value.length < 6) {
                    return 'Das Passwort muss mindestens 6 Zeichen lang sein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passwort bestätigen',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Die Passwörter stimmen nicht überein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        final email = _email;
                        if (email == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Keine E‑Mail‑Adresse vorhanden.'),
                            ),
                          );
                          return;
                        }
                        final code = _codeController.text.trim();
                        final newPassword = _newPasswordController.text;
                        setState(() {
                          _loading = true;
                        });
                        try {
                          final success = await AuthService.verifyRecoveryAndUpdatePassword(
                            email: email,
                            code: code,
                            newPassword: newPassword,
                          );
                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwort wurde erfolgreich zurückgesetzt.'),
                              ),
                            );
                            Navigator.of(context)
                                .pushNamedAndRemoveUntil('/login', (route) => false);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ungültiger Code oder Fehler beim Zurücksetzen.'),
                              ),
                            );
                          }
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fehler beim Zurücksetzen: $error'),
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
                    : const Text('Passwort zurücksetzen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
