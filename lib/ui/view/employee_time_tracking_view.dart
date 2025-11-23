import 'package:flutter/material.dart';

/// Placeholder view for the employee time tracking screen. This screen will
/// later allow employees to check in and out of work, possibly via NFC or
/// a PIN. For now it simply displays a message for testing navigation.
class EmployeeTimeTrackingView extends StatelessWidget {
  const EmployeeTimeTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeiterfassung'),
      ),
      body: const Center(
        child: Text(
          'Hier können Mitarbeiter ihre Arbeitszeit stempeln.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}