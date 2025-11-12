import 'package:flutter/material.dart';

// Import the AuthService for handling login requests.  The service
// resides in lib/services/auth_service.dart.  The relative import
// uses three leading ../ segments to navigate from
// lib/features/auth/pages to lib/services.
import '../../../services/auth_service.dart';

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
  // Password is no longer required for Supabase OTP login,
  // therefore we remove the password controller and state.

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    // No longer needed since we removed the password field.
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Collect form values
      final email = _emailController.text.trim();
      // Send a one‑time password via Supabase.  If successful, the
      // user is navigated to the 2FA page to enter the code.
      AuthService()
          .sendOtp(email: email)
          .then((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamed('/two-factor', arguments: {
          'email': email,
        });
      }).catchError((err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Senden des Codes: ${err.toString()}')),
        );
      });
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
                    border: const OutlineInputBorder(),
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
                // Password field removed.  A hint explains the new flow.
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Nach Eingabe der E‑Mail wird ein 6‑stelliger Code gesendet.',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _submit,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 12),
                // Link to password reset
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwort vergessen ist bei OTP nicht erforderlich')),
                    );
                  },
                  child: const Text('Passwort vergessen?'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ein Code wird per E‑Mail gesendet. Bitte danach eingeben.',
                  style: TextStyle(color: primary.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}