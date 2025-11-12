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
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Sends an OTP to the entered email address via Supabase. Upon
  /// success, navigates to the 2FA page with the email as an argument.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() {
      _loading = true;
    });
    try {
      await AuthService.sendOtp(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code gesendet. Bitte prüfen Sie Ihre E-Mail.')),
      );
      Navigator.of(context).pushNamed('/two-factor', arguments: {'email': email});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Senden des Codes: $error')),
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