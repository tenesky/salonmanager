import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

/// A page that prompts the user to enter their two‑factor authentication
/// code. This UI is kept simple with a single input field and actions to
/// resend the code or use a recovery link. In a real application the
/// resend and recovery actions would be wired up to backend services.
class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({Key? key}) : super(key: key);

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  final TextEditingController _codeController = TextEditingController();
  String? _email;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the email passed via route arguments. This cannot be done in
    // initState because ModalRoute depends on the context being fully
    // initialised. Only assign if not already set to avoid overwriting
    // on hot reload.
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
    super.dispose();
  }

  /// Resends the OTP to the stored email. If no email is known, shows
  /// an error. The resend uses the same endpoint as the initial
  /// request.
  Future<void> _resendCode() async {
    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine E-Mail-Adresse vorhanden.')),
      );
      return;
    }
    try {
      // Resend the code to the existing user. We use the dedicated
      // method to avoid creating a new user record.
      await AuthService.sendOtpForExistingUser(_email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code erneut gesendet.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Senden des Codes: $error')),
      );
    }
  }

  /// Verifies the entered code using Supabase. On success, navigates
  /// to the home page. On failure, shows an error message.
  Future<void> _verifyCode() async {
    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine E-Mail-Adresse vorhanden.')),
      );
      return;
    }
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Code eingeben.')),
      );
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      final success = await AuthService.verifyOtp(email: _email!, code: code);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erfolgreich angemeldet.')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ungültiger Code.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Überprüfen des Codes: $error')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code eingeben'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bitte geben Sie den 6‑stelligen Code ein, der an Ihre E‑Mail gesendet wurde.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _resendCode,
                  child: const Text('Code erneut senden'),
                ),
                TextButton(
                  onPressed: () {
                    // Recovery link or other fallback flows could be implemented here.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recovery-Link nicht verfügbar.')),
                    );
                  },
                  child: const Text('Recovery-Link'),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verifyCode,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Weiter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}