import 'package:flutter/material.dart';

/// The welcome / app intro screen.  Displays a short claim and
/// primary actions to log in or register.  Adheres to the black and
/// gold branding with minimal content.
class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Placeholder for branding / claim
                Text(
                  'SalonManager',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Die All‑in‑One‑Lösung für moderne Salons',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondary.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: secondary),
                      foregroundColor: secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      // Navigate to customer registration by default. Salon‑Owner registration
                      // can be accessed from within the registration screen.
                      Navigator.of(context).pushNamed('/register-customer');
                    },
                    child: const Text('Registrieren'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}