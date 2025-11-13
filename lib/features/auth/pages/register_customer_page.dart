import 'package:flutter/material.dart';
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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _acceptMarketing = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _loading = true;
    });
    try {
      // First sign up with email and password. This creates the user in
      // Supabase Auth. If the email is already registered or invalid,
      // this call will throw an AuthException.
      await AuthService.signUpWithPassword(email: email, password: password);
      // Immediately send a one‑time code to the newly registered user to
      // complete 2FA. Setting shouldCreateUser to false ensures we
      // don’t accidentally create another user record.
      await AuthService.sendOtpForExistingUser(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrierungs‑Code gesendet. Bitte prüfen Sie Ihre E‑Mail.')),
      );
      // Pass the email to the 2FA page for code verification.
      Navigator.of(context).pushNamed('/two-factor', arguments: {'email': email});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Registrierung: $error')),
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
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Ungültige E‑Mail‑Adresse.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte legen Sie ein Passwort fest.';
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
                  if (value == null || value.isEmpty) {
                    return 'Bitte bestätigen Sie Ihr Passwort.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwörter stimmen nicht überein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                onPressed: _loading ? null : _register,
                style: Theme.of(context).brightness == Brightness.dark
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrieren'),
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