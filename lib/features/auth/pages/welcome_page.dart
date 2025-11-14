import 'package:flutter/material.dart';

/// The welcome / app intro screen.
///
/// Displays a short claim and primary actions to log in or register.  The
/// design follows the black and gold branding guidelines.  Additional
/// registration options for customers, salon owners and admins are
/// presented so each user type can find the appropriate sign‑up flow.
class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve primary (black) and secondary (gold) colours from the
    // current theme.  On dark themes the primary colour is white.
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    final Color onSecondary = Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: 'Sprache wechseln',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sprachumschaltung folgt …')),
              );
            },
          ),
          IconButton(
            icon: Icon(
                Theme.of(context).brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'Theme wechseln',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme-Umschaltung folgt …')),
              );
            },
          ),
        ],
      ),
      backgroundColor: primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              // Display the logo depending on the current brightness.  This
              // matches the global branding guidelines.
              Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/login_dark.png'
                    : 'assets/login_light.png',
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                'Die All‑in‑One‑Lösung für\nmoderne Salons',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondary.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              // CTA stack: Login, register for different roles, guest and demo
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Primary action: Login
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: secondary, width: 2),
                      foregroundColor: secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    child: const Text('Anmelden'),
                  ),
                  const SizedBox(height: 16),
                  // Customer registration
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register-customer');
                    },
                    child: const Text('Als Kunde registrieren'),
                  ),
                  const SizedBox(height: 16),
                  // Salon owner registration
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register-salon');
                    },
                    child: const Text('Salon‑Owner registrieren'),
                  ),
                  const SizedBox(height: 16),
                  // Admin registration
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register-admin');
                    },
                    child: const Text('Admin registrieren'),
                  ),
                  const SizedBox(height: 16),
                  // Guest access
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: secondary, width: 2),
                      foregroundColor: secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      // Navigate directly to the home page without authentication.
                      Navigator.of(context).pushNamed('/home');
                    },
                    child: const Text('Als Gast fortfahren'),
                  ),
                  const SizedBox(height: 24),
                  // Demo view
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/demo');
                      },
                      child: const Text(
                        'Demo ansehen',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Footer with Impressum and version number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/impressum');
                    },
                    child: Text(
                      'Impressum',
                      style: TextStyle(
                        color: secondary.withOpacity(0.6),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    'v0.1',
                    style: TextStyle(
                      color: secondary.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
