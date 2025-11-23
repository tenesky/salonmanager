import 'package:flutter/material.dart';

/// Placeholder view for managing customer bookings. The owner or admin
/// will eventually be able to review, reschedule and cancel bookings
/// from this screen. For now it contains a placeholder message.
class OwnerManageBookingsView extends StatelessWidget {
  const OwnerManageBookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termine verwalten'),
      ),
      body: const Center(
        child: Text(
          'Hier können Sie gebuchte Termine einsehen, verschieben oder stornieren.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}