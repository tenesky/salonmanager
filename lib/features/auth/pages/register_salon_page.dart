import 'package:flutter/material.dart';

// Import AuthService to handle salon owner registration and send 2FA
import '../../../services/auth_service.dart';

/// Registration screen for new salon owners. This form includes additional
/// fields to capture salon information. As with the customer registration,
/// validation is basic and serves as a placeholder until backend integration.
class RegisterSalonPage extends StatefulWidget {
  const RegisterSalonPage({Key? key}) : super(key: key);

  @override
  State<RegisterSalonPage> createState() => _RegisterSalonPageState();
}

class _RegisterSalonPageState extends State<RegisterSalonPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // Password controller is removed; OTP login does not require a password.
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _salonAddressController = TextEditingController();

  @override
  void dispose() {
    _ownerNameController.dispose();
    _emailController.dispose();
    _salonNameController.dispose();
    _salonAddressController.dispose();
    super.dispose();
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
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Ihr Name',
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final ownerName = _ownerNameController.text.trim();
                    final email = _emailController.text.trim();
                    final salonName = _salonNameController.text.trim();
                    final salonAddress = _salonAddressController.text.trim();
                    // Send an OTP to initiate registration.  Owner data and salon
                    // details will be stored later via the profile and salons tables.
                    AuthService()
                        .sendOtp(email: email)
                        .then((_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bestätigungscode gesendet')),
                      );
                      // Navigate to the 2FA screen to verify the code.
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