import 'package:flutter/material.dart';
import '../../../core/connectivity_provider.dart';

/// Shows a full‑screen message when the device is offline.  Includes a
/// retry button that triggers a manual connectivity check.  The app
/// overlays this widget via the [ConnectivityProvider] when offline.
class OfflinePage extends StatelessWidget {
  const OfflinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Keine Internetverbindung',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bitte prüfe deine Verbindung und versuche es erneut.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await ConnectivityProvider.instance.retry();
                },
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}