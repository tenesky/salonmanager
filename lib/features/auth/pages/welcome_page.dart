import 'package:flutter/material.dart';

/// The welcome / app intro screen.  Displays a short claim and
/// primary actions to log in or register.  Adheres to the black and
/// gold branding with minimal content.
class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve primary (black) and secondary (gold) colors from the current
    // theme. These are defined in `core/theme.dart` and ensure
    // consistency with the global design guidelines【178541174647508†L13-L15】.
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    final Color onSecondary = Colors.black;

    return Scaffold(
      // Transparent AppBar with language and theme toggles
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: 'Sprache wechseln',
            onPressed: () {
              // TODO: implement locale switching (DE/EN). For now just show a SnackBar.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sprachumschaltung folgt …')),
              );
            },
          ),
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode),
            tooltip: 'Theme wechseln',
            onPressed: () {
              // TODO: implement theme switching. For now inform the user.
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
              // Hero section with custom logo asset. This image comes from
              // the provided SalonManager branding and contains the
              // scissors and "S" motif as well as the brand name. The tagline
              // appears below the image.
              // Display a different logo depending on the current brightness
              // of the theme. When the app is in dark mode a version of the
              // logo with a dark background is shown; otherwise the light
              // variant is used.  The images are stored in the `assets` folder
              // and declared in pubspec.yaml.  A fixed height is applied
              // to ensure consistent layout across devices.
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
              // CTA stack: Login, Register, Guest
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Primary action: anmelden (outlined in gold, dark background)
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
                  // Secondary action: registrieren (gold filled)
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
                    child: const Text('Registrieren'),
                  ),
                  const SizedBox(height: 16),
                  // Tertiary action: Als Gast fortfahren (outlined gold)
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
                  // Demo ansehen: simple text button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigate to the demo route (home) so the user can explore
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
                      // TODO: navigate to impressum page when implemented
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