import 'package:flutter/material.dart';

/// Home screen for the owner/administrator role. This page provides
/// navigation to various administrative functions such as managing
/// employees, schedules, bookings, leave requests, attendance and
/// reports. Each option currently leads to a placeholder view so that
/// navigation can be tested and extended in future steps.
class OwnerHomeView extends StatelessWidget {
  const OwnerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Willkommen im Admin‑Bereich! Bitte wählen Sie eine Aktion.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, 'owner_manage_employees');
              },
              child: const Text('Mitarbeiter verwalten'),
            ),
            const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, 'owner_manage_services');
          },
          child: const Text('Services verwalten'),
        ),
        const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, 'owner_manage_schedule');
              },
              child: const Text('Dienstplan verwalten'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, 'owner_manage_bookings');
              },
              child: const Text('Termine verwalten'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, 'owner_manage_leave_requests');
              },
              child: const Text('Abwesenheitsanträge'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, 'owner_view_attendance');
              },
              child: const Text('Zeiterfassung & Attendance'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, 'owner_reports');
              },
              child: const Text('Statistiken & Berichte'),
            ),
          ],
        ),
      ),
    );
  }
}