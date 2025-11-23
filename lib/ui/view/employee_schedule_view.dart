import 'package:flutter/material.dart';

/// Placeholder view showing the employee's shift schedule. This page will
/// eventually allow employees to view their upcoming shifts and any
/// assigned service times. Currently it contains only a message so that
/// navigation can be tested.
class EmployeeScheduleView extends StatelessWidget {
  const EmployeeScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Dienstplan'),
      ),
      body: const Center(
        child: Text(
          'Hier können Mitarbeiter ihren Dienstplan sehen.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}