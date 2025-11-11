import 'package:flutter/material.dart';
import 'package:salonmanager/services/db_service.dart';

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
/// Displays a combined overview of today's appointments and upcoming
/// appointments. This implementation retrieves all pending and
/// confirmed bookings from the database and groups them by date.
class TodayUpcomingBookingsPage extends StatefulWidget {
  const TodayUpcomingBookingsPage({Key? key}) : super(key: key);

  @override
  State<TodayUpcomingBookingsPage> createState() => _TodayUpcomingBookingsPageState();
}

class _TodayUpcomingBookingsPageState extends State<TodayUpcomingBookingsPage> {
  /// Indicates whether the appointment list is currently loading.
  bool _loading = false;

  /// All appointments (pending or confirmed) loaded from the database.
  /// Each entry contains: id, datetime, customer, service, stylist,
  /// status. The datetime is stored as a local DateTime.
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  /// Queries the database for all bookings with status 'pending' or
  /// 'confirmed' and populates [_appointments] accordingly. Joins
  /// related tables to get human‑readable names. Errors are caught
  /// silently and will leave the list empty.
  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
    });
    try {
      final conn = await DbService.getConnection();
      final results = await conn.query(
        '''
        SELECT b.id,
               b.start_datetime AS startDateTime,
               b.duration,
               c.first_name AS firstName,
               c.last_name AS lastName,
               srv.name AS serviceName,
               st.name AS stylistName,
               b.status
        FROM bookings b
        JOIN customers c ON b.customer_id = c.id
        JOIN services srv ON b.service_id = srv.id
        JOIN stylists st ON b.stylist_id = st.id
        WHERE b.status IN ('pending','confirmed')
        ORDER BY b.start_datetime ASC
        ''',
      );
      final List<Map<String, dynamic>> loaded = [];
      for (final row in results) {
        DateTime dt;
        final dynamic v = row['startDateTime'];
        if (v is DateTime) {
          dt = v.toLocal();
        } else if (v is String) {
          dt = DateTime.parse(v).toLocal();
        } else {
          dt = DateTime.now();
        }
        loaded.add({
          'id': row['id'],
          'datetime': dt,
          'customer': '${row['firstName']} ${row['lastName']}',
          'service': row['serviceName'],
          'stylist': row['stylistName'],
          'status': row['status'],
        });
      }
      await conn.close();
      setState(() {
        _appointments = loaded;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Returns appointments scheduled for the same calendar day as
  /// [reference].
  List<Map<String, dynamic>> _getTodayAppointments(DateTime reference) {
    return _appointments.where((appt) {
      final DateTime dt = appt['datetime'] as DateTime;
      return dt.year == reference.year && dt.month == reference.month && dt.day == reference.day;
    }).toList();
  }

  /// Returns appointments that occur strictly after the end of the
  /// given day [reference].
  List<Map<String, dynamic>> _getUpcomingAppointments(DateTime reference) {
    return _appointments.where((appt) {
      final DateTime dt = appt['datetime'] as DateTime;
      final DateTime endOfToday = DateTime(reference.year, reference.month, reference.day, 23, 59, 59);
      return dt.isAfter(endOfToday);
    }).toList();
  }
  
  /// Builds a status chip with appropriate colour and label. Uses the
  /// theme's secondary colour for confirmed bookings and grey for pending.
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

  /// Builds a card widget for a single appointment entry.
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
          // Navigate to the professional booking detail page. Pass the booking id
          // so that the detail page can load additional information from the database.
          Navigator.of(context).pushNamed(
            '/bookings/pro-detail',
            arguments: {'id': appointment['id']},
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Heute',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (today.isEmpty)
                    const Text('Keine Termine heute.'),
                  for (final appointment in today)
                    _buildAppointmentCard(context, appointment),
                  const SizedBox(height: 24),
                  Text(
                    'Nächste Termine',
                    style: Theme.of(context).textTheme.titleLarge,
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
              // Use Material 3 typography: titleLarge replaces headline6.
              style: Theme.of(context).textTheme.titleLarge,
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
              style: Theme.of(context).textTheme.titleLarge,
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