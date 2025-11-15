import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

/// A simple account settings page that displays the current user's
/// email address and provides a button to log out.  Logging out
/// clears the Supabase session and redirects the user back to the
/// login screen.  This page can be extended later with profile
/// editing, password change or two‑factor setup.
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? email = AuthService.currentUserEmail();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email != null) ...[
              Text(
                'Eingeloggt als',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              onPressed: () async {
                // Sign out via the AuthService.  On success navigate
                // back to the login screen (or welcome page).
                await AuthService.logout();
                // Remove all pages from the stack and go to login.
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Abmelden'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}