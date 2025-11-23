import 'package:flutter/material.dart';

/// Placeholder view for managing leave requests. On this page the owner
/// will be able to approve or reject vacation, sick or other leave
/// requests submitted by employees. For now it displays only a message.
class OwnerManageLeaveRequestsView extends StatelessWidget {
  const OwnerManageLeaveRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abwesenheitsanträge'),
      ),
      body: const Center(
        child: Text(
          'Hier genehmigen oder lehnen Sie Urlaubs- und Krankheitsanträge ab.\nDiese Seite ist aktuell ein Platzhalter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}