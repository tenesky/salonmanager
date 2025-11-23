import 'package:flutter/material.dart';

/// Placeholder view for viewing employee attendance records. This page
/// will later allow the owner to review clock-in and clock-out times,
/// calculate hours worked and export reports. Currently it shows
/// only a message for testing navigation.
class OwnerViewAttendanceView extends StatelessWidget {
  const OwnerViewAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeiterfassung & Attendance'),
      ),
      body: const Center(
        child: Text(
          'Hier sehen Sie die Arbeitszeiten aller Mitarbeiter.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}