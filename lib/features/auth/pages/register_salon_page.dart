import 'package:flutter/material.dart';
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
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _salonAddressController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _emailController.dispose();
    _salonNameController.dispose();
    _salonAddressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() {
      _loading = true;
    });
    try {
      await AuthService.sendOtp(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrierungs-Code gesendet. Bitte prüfen Sie Ihre E-Mail.')),
      );
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
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Ungültige E‑Mail‑Adresse.';
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