import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zwei‑Faktor‑Authentifizierung'),
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
                  onPressed: () {
                    // TODO: implement resend code
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code erneut senden nicht implementiert')),
                    );
                  },
                  child: const Text('Code erneut senden'),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: implement recovery link
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recovery‑Link nicht implementiert')),
                    );
                  },
                  child: const Text('Recovery‑Link'),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // In a real app the code would be validated here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eingegebener Code: ${_codeController.text}')),
                  );
                },
                child: const Text('Weiter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}