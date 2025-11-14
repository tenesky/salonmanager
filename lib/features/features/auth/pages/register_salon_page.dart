import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

/// Registration screen for new salon owners.
///
/// This form collects the owner’s first and last name in addition to the
/// salon’s name and address.  After sign‑up an OTP is sent via email
/// for two‑factor authentication.  Validation is basic and serves as a
/// placeholder until backend integration.
class RegisterSalonPage extends StatefulWidget {
  const RegisterSalonPage({Key? key}) : super(key: key);

  @override
  State<RegisterSalonPage> createState() => _RegisterSalonPageState();
}

class _RegisterSalonPageState extends State<RegisterSalonPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _salonAddressController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _salonNameController.dispose();
    _salonAddressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _loading = true;
    });
    // Schritt 1: Salon-Owner registrieren – bei Fehler abbrechen
    try {
      await AuthService.signUpWithPassword(email: email, password: password);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Registrierung: $error')),
      );
      setState(() {
        _loading = false;
      });
      return;
    }

    // Schritt 2: OTP-Code schicken – Fehler hier sind NICHT kritisch
    try {
      await AuthService.sendOtpForExistingUser(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrierungs‑Code gesendet. Bitte prüfen Sie Ihre E‑Mail.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      if (message.contains('request') && message.contains('second')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code wurde bereits gesendet. Bitte prüfen Sie Ihre E‑Mail.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Senden des Codes: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushNamed('/two-factor', arguments: {'email': email});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon‑Owner registrieren'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Vorname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie Ihren Vornamen ein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nachname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie Ihren Nachnamen ein.';
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
              TextFormField(
                controller: _salonNameController,
                decoration: const InputDecoration(
                  labelText: 'Salon‑Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie den Namen Ihres Salons ein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salonAddressController,
                decoration: const InputDecoration(
                  labelText: 'Salon‑Adresse',
                  border: OutlineInputBorder(),
                ),
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
