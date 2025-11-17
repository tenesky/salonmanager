import 'dart:async';

import 'package:flutter/material.dart';
import 'package:salonmanager/services/auth_service.dart';

/// A simple splash page that shows the SalonManager logo on a dark
/// background while the app is launching. After a short delay it
/// navigates to the login screen. The design matches the provided
/// mockup with a dark patterned backdrop, a golden logo centred on the
/// page, a circular progress indicator using the app's secondary
/// colour and a "Loading…" label underneath.
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Delay briefly and then decide whether to show the login page or
    // skip directly to the home page.  If the user has an active
    // Supabase session, the app will navigate to '/home'.  Otherwise
    // it navigates to '/login'.  This ensures that sessions persist
    // across app restarts without requiring the user to log in again.
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      try {
        // Use AuthService to check if a session exists.  This call is
        // synchronous because Supabase caches the session in memory.
        final bool loggedIn = AuthService.isLoggedIn();
        if (loggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (_) {
        // Fallback to login on any unexpected error.
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display the full SalonManager logo. Use the asset directly
            // instead of the themed background so the logo stands out on
            // the plain dark backdrop.
            Image.asset(
              'assets/logo_full.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            // Circular progress indicator with yellow accent. The
            // indicator inherits the secondary colour from the theme to
            // match the golden brand colour. Use a small stroke width
            // for a subtle look.
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
              strokeWidth: 4,
            ),
            const SizedBox(height: 20),
            // Loading text below the spinner. Use the bodyMedium style
            // for appropriate typography and override the colour to
            // contrast against the dark background. Use English
            // localisation to match the provided design.
            Text(
              'Loading…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}