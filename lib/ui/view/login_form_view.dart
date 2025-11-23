import 'package:flutter/material.dart';
import 'package:multiplat/core/viewmodel/login_viewmodel.dart';
import 'package:provider/provider.dart';

/// A login form that accepts email and password. The role is passed via
/// constructor and determines which role the user is attempting to log in as.
class LoginFormView extends StatefulWidget {
  final String role;

  const LoginFormView({Key? key, required this.role}) : super(key: key);

  @override
  State<LoginFormView> createState() => _LoginFormViewState();
}

class _LoginFormViewState extends State<LoginFormView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptLogin(BuildContext context) async {
    final model = Provider.of<LoginViewModel>(context, listen: false);
    final success = await model.login(
      _emailController.text.trim(),
      _passwordController.text,
      widget.role,
    );
    if (success) {
      // After a successful login, navigate to the appropriate home
      // screen based on the user's role. Customers are taken to
      // the customer home page, employees to the employee home page,
      // and admins/owners to the owner home page.
      if (widget.role == 'customer') {
        Navigator.pushNamedAndRemoveUntil(
            context, 'customer_home', (route) => false);
      } else if (widget.role == 'admin') {
        Navigator.pushNamedAndRemoveUntil(
            context, 'owner_home', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, 'employee_home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, model, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.role == 'customer'
                    ? 'Kunden-Login'
                    : (widget.role == 'admin'
                        ? 'Admin-Login'
                        : 'Mitarbeiter-Login'),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  if (model.error != null) ...[
                    Text(
                      model.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton(
                    onPressed: model.loading
                        ? null
                        : () => _attemptLogin(context),
                    child: model.loading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Einloggen'),
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