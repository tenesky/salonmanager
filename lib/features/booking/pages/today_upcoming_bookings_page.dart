import 'package:flutter/material.dart';

/// Displays a combined overview of today's appointments and upcoming
/// appointments for stylists or managers. Each section contains
/// card‑styled entries listing the appointment time, customer,
/// service, stylist and current status. Status chips use the
/// application accent color for confirmed bookings and a neutral
/// grey for pending bookings to clearly differentiate the states.
///
/// This widget implements Screen 29 (Heute / Nächste Termine) of the
/// booking management module described in the Pflichtenheft. It
/// allows professionals to quickly see which appointments are due
/// today and what comes next. In this mock implementation the
/// appointments are hard‑coded; later iterations will load real
/// data from the backend.
class TodayUpcomingBookingsPage extends StatelessWidget {
  TodayUpcomingBookingsPage({Key? key}) : super(key: key);

  /// Sample data representing scheduled appointments. Each entry
  /// contains an identifier, the scheduled date and time, the
  /// customer's name, the requested service, the assigned stylist
  /// and the current status. A real implementation would replace
  /// this list with data fetched from the API and maintained via
  /// state management (e.g. Riverpod).
  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 1,
      'datetime': DateTime(2025, 11, 11, 9, 30),
      'customer': 'Laura Fischer',
      'service': 'Haarschnitt (Damen)',
      'stylist': 'Anna',
      'status': 'confirmed',
    },
    {
      'id': 2,
      'datetime': DateTime(2025, 11, 11, 14, 0),
      'customer': 'Peter Schneider',
      'service': 'Bartpflege',
      'stylist': 'Max',
      'status': 'pending',
    },
    {
      'id': 3,
      'datetime': DateTime(2025, 11, 12, 10, 0),
      'customer': 'Julia Weber',
      'service': 'Balayage',
      'stylist': 'Sofia',
      'status': 'confirmed',
    },
    {
      'id': 4,
      'datetime': DateTime(2025, 11, 13, 15, 0),
      'customer': 'Andreas Koch',
      'service': 'Herrenhaarschnitt',
      'stylist': 'Tom',
      'status': 'pending',
    },
  ];

  /// Filters the appointments to those occurring on the same day as
  /// [reference]. This simple comparison ignores timezone
  /// conversions because all mock dates are assumed to be in the
  /// same timezone. In production the API should supply ISO strings
  /// with timezone information.
  List<Map<String, dynamic>> _getTodayAppointments(DateTime reference) {
    return _appointments.where((appt) {
      final DateTime dt = appt['datetime'] as DateTime;
      return dt.year == reference.year &&
          dt.month == reference.month &&
          dt.day == reference.day;
    }).toList();
  }

  /// Returns appointments after the day of [reference].
  List<Map<String, dynamic>> _getUpcomingAppointments(DateTime reference) {
    return _appointments.where((appt) {
      final DateTime dt = appt['datetime'] as DateTime;
      final DateTime endOfToday = DateTime(reference.year, reference.month, reference.day, 23, 59, 59);
      return dt.isAfter(endOfToday);
    }).toList();
  }

  /// Builds a status chip with appropriate colour and label. Uses the
  /// theme's accent colour for confirmed bookings and a neutral
  /// grey for pending bookings. Additional statuses can be added
  /// here in the future.
  Widget _buildStatusChip(BuildContext context, String? status) {
    final String text;
    final Color color;
    switch (status) {
      case 'confirmed':
        text = 'Bestätigt';
        color = Theme.of(context).colorScheme.secondary;
        break;
      case 'pending':
        text = 'Angefragt';
        color = Colors.grey;
        break;
      default:
        text = status ?? '';
        color = Colors.grey;
    }
    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  /// Builds a card widget for a single appointment entry. The card
  /// shows the time, customer, service and stylist, followed by a
  /// status chip aligned to the right.
  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> appointment) {
    final DateTime dt = appointment['datetime'] as DateTime;
    final String timeString =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        title: Text(timeString),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${appointment['customer']} – ${appointment['service']}'),
            Text('Stylist: ${appointment['stylist']}'),
          ],
        ),
        trailing: _buildStatusChip(context, appointment['status'] as String?),
        onTap: () {
          // Optionally navigate to the booking detail view using the existing route.
          Navigator.of(context).pushNamed(
            '/bookings/detail',
            arguments: {
              'date': dt.toIso8601String(),
              'time': timeString,
              'customerName': appointment['customer'],
              'serviceTitle': appointment['service'],
              'stylistName': appointment['stylist'],
              'status': appointment['status'],
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<Map<String, dynamic>> today = _getTodayAppointments(now);
    final List<Map<String, dynamic>> upcoming = _getUpcomingAppointments(now);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heute & Nächste Termine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section for today's appointments
            Text(
              'Heute',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 8),
            if (today.isEmpty)
              const Text('Keine Termine heute.'),
            for (final appointment in today)
              _buildAppointmentCard(context, appointment),
            const SizedBox(height: 24),
            // Section for upcoming appointments
            Text(
              'Nächste Termine',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              const Text('Keine kommenden Termine.'),
            for (final appointment in upcoming)
              _buildAppointmentCard(context, appointment),
          ],
        ),
      ),
    );
  }
}