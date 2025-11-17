import 'package:flutter/material.dart';

/// Displays a 403 Forbidden page when the user lacks permission to
/// access a route or resource.  Includes a button to return to the
/// start page.
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zugriff verweigert'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                '403',
                style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Du hast keine Berechtigung, diese Seite zu sehen.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('Zur Startseite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}