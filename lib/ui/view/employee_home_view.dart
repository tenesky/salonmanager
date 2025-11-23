import 'package:flutter/material.dart';

/// Home screen for employees (and admins). This page is shown after a
/// successful login for non-customer roles. From here the user can
/// navigate to their daily overview, view their shift schedule,
/// perform time tracking or submit leave requests. Each option
/// currently leads to a placeholder page so that navigation can be
/// tested and extended in future steps.
class EmployeeHomeView extends StatelessWidget {
  const EmployeeHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mitarbeiter‑Startseite'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Willkommen! Was möchten Sie als Nächstes tun?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to the overview page (heute)
                Navigator.pushNamed(context, 'employee_overview');
              },
              child: const Text('Heute – meine Termine & Schicht'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to the shift schedule page
                Navigator.pushNamed(context, 'employee_schedule');
              },
              child: const Text('Mein Dienstplan'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to the time tracking page
                Navigator.pushNamed(context, 'employee_time_tracking');
              },
              child: const Text('Zeiterfassung'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to the leave request page
                Navigator.pushNamed(context, 'employee_leave_request');
              },
              child: const Text('Abwesenheit beantragen'),
            ),
          ],
        ),
      ),
    );
  }
}