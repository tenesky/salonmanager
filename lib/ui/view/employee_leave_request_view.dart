import 'package:flutter/material.dart';

/// Placeholder view for the employee leave request screen. This screen will
/// eventually provide a form for requesting vacation, sick days or
/// other types of leave. Currently it shows only a message so that
/// navigation can be tested.
class EmployeeLeaveRequestView extends StatelessWidget {
  const EmployeeLeaveRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abwesenheit beantragen'),
      ),
      body: const Center(
        child: Text(
          'Hier können Mitarbeiter Urlaub oder Krankheit beantragen.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}