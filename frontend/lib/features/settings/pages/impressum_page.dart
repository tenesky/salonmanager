import 'package:flutter/material.dart';
import '../../../common/themed_background.dart';

/// A simple Impressum (legal notice) page.  Displays mandatory
/// information about the app provider.  The page uses the
/// ThemedBackground widget to ensure the branding is consistent in
/// both light and dark modes.
class ImpressumPage extends StatelessWidget {
  const ImpressumPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impressum'),
      ),
      body: ThemedBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'SalonManager GmbH',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Musterstraße 1\n12345 Musterstadt\nDeutschland'),
              SizedBox(height: 16),
              Text('Vertreten durch:\nMax Mustermann (Geschäftsführer)'),
              SizedBox(height: 16),
              Text('Kontakt:\nTelefon: +49 123 4567890\nE‑Mail: info@salonmanager.de'),
              SizedBox(height: 16),
              Text('Umsatzsteuer‑Identifikationsnummer gemäß §27a UStG:\nDE123456789'),
              SizedBox(height: 16),
              Text(
                'Verantwortlich für den Inhalt nach §55 Abs. 2 RStV:\nMax Mustermann\nMusterstraße 1\n12345 Musterstadt',
              ),
            ],
          ),
        ),
      ),
    );
  }
}