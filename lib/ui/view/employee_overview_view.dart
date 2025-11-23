import 'package:flutter/material.dart';

/// Placeholder view showing the employee's overview for today. In a future
/// step this page will display the employee's current shift and any
/// appointments scheduled for today. For now it only shows a message.
class EmployeeOverviewView extends StatelessWidget {
  const EmployeeOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heute – Übersicht'),
      ),
      body: const Center(
        child: Text(
          'Hier sehen Mitarbeiter ihre heutige Schicht und Termine.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}