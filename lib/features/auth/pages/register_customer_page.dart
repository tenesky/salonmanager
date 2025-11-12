import 'package:flutter/material.dart';

// Import AuthService to handle customer registration and 2FA
import '../../../services/auth_service.dart';

/// Registration screen for new customers. This form collects minimal
/// information required to create an account. Additional fields can be
/// added as needed. Validation logic is kept simple for demonstration.
class RegisterCustomerPage extends StatefulWidget {
  const RegisterCustomerPage({Key? key}) : super(key: key);

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // Password controller is removed; OTP login does not require a password.
  bool _acceptMarketing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrieren'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie Ihren Namen ein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E‑Mail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie Ihre E‑Mail ein.';
                  }
                  if (!value.contains('@')) {
                    return 'Ungültige E‑Mail‑Adresse.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // No password field needed for OTP signup
              const SizedBox(height: 0),
              Row(
                children: [
                  Checkbox(
                    value: _acceptMarketing,
                    onChanged: (value) {
                      setState(() {
                        _acceptMarketing = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text('Ich möchte Neuigkeiten und Angebote per Push erhalten.'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text.trim();
                    final email = _emailController.text.trim();
                    // Split the name into first and last name.  If only one
                    // segment is provided it becomes the first name.
                    final parts = name.split(' ');
                    final firstName = parts.isNotEmpty ? parts.first : name;
                    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                    // Send an OTP to register and log in.  We ignore the
                    // first/last name for now; they can be stored in the
                    // profile table after verification.
                    AuthService()
                        .sendOtp(email: email)
                        .then((_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bestätigungscode gesendet')),
                      );
                      Navigator.of(context).pushReplacementNamed('/two-factor', arguments: {
                        'email': email,
                      });
                    }).catchError((err) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler beim Senden des Codes: ${err.toString()}')),
                      );
                    });
                  }
                },
                // In dunklen Themes soll der Button weiß sein mit schwarzer Schrift.
                style: Theme.of(context).brightness == Brightness.dark
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                child: const Text('Registrieren'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Sie haben bereits ein Konto? Anmelden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}