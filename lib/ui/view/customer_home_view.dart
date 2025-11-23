import 'package:flutter/material.dart';

/// Home screen for customers. This is the landing page after a successful
/// login for users with the role `customer`. From here the user can
/// navigate to book a new appointment or view their existing appointments.
class CustomerHomeView extends StatelessWidget {
  const CustomerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kunden‑Startseite'),
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
                // Navigate to the booking page. This page is a placeholder
                // for now and will be implemented in a future step.
                Navigator.pushNamed(context, 'customer_book_service');
              },
              child: const Text('Termin buchen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to view existing appointments. This page is
                // currently a placeholder.
                Navigator.pushNamed(context, 'customer_appointments');
              },
              child: const Text('Meine Termine'),
            ),
          ],
        ),
      ),
    );
  }
}