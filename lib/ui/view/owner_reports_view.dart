import 'package:flutter/material.dart';

/// Placeholder view for displaying business reports and statistics.
/// Eventually this page will show metrics such as revenue per
/// service, employee utilisation, no-show rates and other KPIs. For
/// now it contains a placeholder message.
class OwnerReportsView extends StatelessWidget {
  const OwnerReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken & Berichte'),
      ),
      body: const Center(
        child: Text(
          'Hier finden Sie Auswertungen und Kennzahlen des Salons.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}