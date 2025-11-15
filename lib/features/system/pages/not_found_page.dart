import 'package:flutter/material.dart';

/// A page displayed when a user navigates to an unknown route.
///
/// It shows a friendly 404 message and a button to return to the
/// start page.  The [onUnknownRoute] handler in `app.dart` will
/// navigate to this page when a route cannot be resolved.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seite nicht gefunden'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                '404',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Die angeforderte Seite existiert nicht.',
                style: Theme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
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
