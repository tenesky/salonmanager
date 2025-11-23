import 'package:flutter/material.dart';

/// Placeholder view for managing the staff schedule. This page will later
/// provide tools to create, edit and assign shifts, view conflicts and
/// handle recurring schedules. For now it displays a message.
class OwnerManageScheduleView extends StatelessWidget {
  const OwnerManageScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dienstplan verwalten'),
      ),
      body: const Center(
        child: Text(
          'Hier verwalten Sie die Schichten und Arbeitszeiten.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}