import 'package:flutter/material.dart';
import 'package:multiplat/core/viewmodel/register_viewmodel.dart';
import 'package:provider/provider.dart';

/// A registration form for new users. Users can choose between customer and
/// employee roles when registering. For simplicity employees created via this
/// form will have to be approved or updated by an admin in the backend.
class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _attemptRegister(BuildContext context) async {
    final model = Provider.of<RegisterViewModel>(context, listen: false);
    if (_passwordController.text != _passwordConfirmController.text) {
      model.setError('Passwörter stimmen nicht überein');
      return;
    }
    final success = await model.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _selectedRole,
    );
    if (success) {
      // Nach erfolgreicher Registrierung zurück zum Login
      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterViewModel>(
      create: (_) => RegisterViewModel(),
      child: Consumer<RegisterViewModel>(
        builder: (context, model, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Registrieren'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Passwort',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordConfirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Passwort bestätigen',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Rolle:'),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(
                            value: 'customer',
                            child: Text('Kunde'),
                          ),
                          DropdownMenuItem(
                            value: 'employee',
                            child: Text('Mitarbeiter'),
                          ),
                        ],
                        onChanged: model.loading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedRole = value ?? 'customer';
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (model.error != null) ...[
                    Text(
                      model.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton(
                    onPressed:
                        model.loading ? null : () => _attemptRegister(context),
                    child: model.loading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Registrieren'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}