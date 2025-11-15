import 'package:flutter/material.dart';

/// A page displayed when the backend is in maintenance mode.
///
/// This page informs the user that maintenance is ongoing and asks
/// them to check back later.  It can be navigated to programmatically
/// when the backend returns a maintenance status code or flag.  The
/// user can close the app or return to the home screen if they wish.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wartungsmodus'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 16),
              Text(
                'Wir führen gerade Wartungsarbeiten durch.',
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bitte versuche es später noch einmal. Vielen Dank für dein Verständnis!',
                style: Theme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to home; if home cannot load because maintenance
                  // persists, the user will see this page again on backend check.
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
                },
                child: const Text('Zurück zur Startseite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}