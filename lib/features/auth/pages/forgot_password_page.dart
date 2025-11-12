import 'package:flutter/material.dart';

/// Page to initiate the password reset process. The user enters their
/// email address, and on submission they are taken to the reset
/// screen. In a real application this would trigger a backend call
/// to send a reset code.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

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
              'Die Anmeldung erfolgt per E‑Mail‑Code. Ein Passwort ist nicht erforderlich. '
              'Wenn Sie dennoch ein Passwort zurücksetzen möchten, können Sie dies über das Supabase‑Dashboard konfigurieren.',
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
              onPressed: null,
              child: const Text('Zurücksetzen nicht verfügbar'),
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