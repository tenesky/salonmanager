import 'package:flutter/material.dart';

/// A simple selection screen for users to choose whether they are logging in
/// as a customer, an employee or as an owner/admin. Non-customer users
/// should pick either the employee or admin button depending on their
/// assigned role. There is also a button to navigate to the registration
/// page for new users.
class LoginSelectionView extends StatelessWidget {
  const LoginSelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anmeldung'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the login form with the customer role
                Navigator.pushNamed(context, 'loginForm', arguments: 'customer');
              },
              child: const Text('Als Kunde einloggen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to the login form with the employee role
                Navigator.pushNamed(context, 'loginForm', arguments: 'employee');
              },
              child: const Text('Als Mitarbeiter einloggen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to the login form with the admin/owner role
                Navigator.pushNamed(context, 'loginForm', arguments: 'admin');
              },
              child: const Text('Als Besitzer/Admin einloggen'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Navigate to the registration page
                Navigator.pushNamed(context, 'register');
              },
              child: const Text('Neu registrieren'),
            ),
          ],
        ),
      ),
    );
  }
}