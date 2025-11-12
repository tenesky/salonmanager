import 'package:flutter/material.dart';

/// Displays a success message after a booking has been completed.
///
/// This page appears after the booking summary and shows a large
/// confirmation icon, a short message, and actions to add the
/// appointment to the calendar or view existing bookings. The
/// implementation loosely follows the description of the
/// success/confirmation screen in the specification for Wizard 8
/// (Erfolg)【522868310347694†L176-L183】.
class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erfolg'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 96, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Termin gebucht!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dein Termin wurde erfolgreich gebucht.\nWir haben eine Bestätigung per E‑Mail gesendet.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // In a real app, this would integrate with the device
                  // calendar. For now we just show a snackbar.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zum Kalender hinzugefügt')),
                  );
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Zum Kalender hinzufügen'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/bookings');
                },
                child: const Text('Meine Buchungen ansehen'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/settings/notifications');
                },
                child: const Text('Benachrichtigungen verwalten'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}