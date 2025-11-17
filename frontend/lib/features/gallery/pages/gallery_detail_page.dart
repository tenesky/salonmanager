import 'package:flutter/material.dart';

/// Detail page for a gallery item. Displays a larger image with
/// description and a button to start a booking. Expects the image
/// data (id, asset, description, etc.) to be passed via
/// [ModalRoute.settings.arguments] as a Map<String, dynamic>.
class GalleryDetailPage extends StatelessWidget {
  const GalleryDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text('Keine Bildinformationen verfügbar.')),
      );
    }
    final String asset = args['asset'] as String;
    final String description = args['description'] as String;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galerie'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to the first step of the booking wizard. In
                        // a fully implemented version, we might preselect
                        // certain parameters based on the gallery image.
                        Navigator.pushNamed(context, '/booking/select-salon');
                      },
                      child: const Text('Termin buchen'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}