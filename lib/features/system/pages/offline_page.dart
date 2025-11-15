import 'package:flutter/material.dart';
import '../../../core/connectivity_provider.dart';

/// A simple full‑screen page shown when the device is offline.
///
/// It displays a message, an icon and a button to retry the connection.
/// The button calls [ConnectivityProvider.retry] which rechecks
/// connectivity and hides this page if the connection is restored.
class OfflinePage extends StatelessWidget {
  const OfflinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 16),
              Text(
                'Keine Internetverbindung',
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bitte prüfe deine Verbindung und versuche es erneut.',
                style: Theme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Trigger a manual retry.
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