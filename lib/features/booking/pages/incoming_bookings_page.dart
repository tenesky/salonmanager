import 'package:flutter/material.dart';
import '../widgets/reschedule_dialog.dart';
import 'package:salonmanager/services/db_service.dart';

/// A page that displays a list of incoming booking requests for
/// stylists or managers. Each request is represented by a card
/// showing the customer name, requested service and the requested
/// appointment date and time. Two actions are provided: accepting
/// the booking or declining it. Declining will eventually open the
/// rescheduling dialog (Screen 31) once implemented. Until then
/// a placeholder dialog is shown. Accepting removes the request
/// from the list and shows a snackbar confirming the action.
///
/// This page corresponds to Screen 28 in the booking management
/// module of the specification【848593805200639†L219-L223】. Because there
/// is no backend yet, a few mock requests are generated when the
/// page is first displayed. In a future iteration these will be
/// fetched from the backend via an API call.
class IncomingBookingsPage extends StatefulWidget {
  const IncomingBookingsPage({Key? key}) : super(key: key);

  @override
  State<IncomingBookingsPage> createState() => _IncomingBookingsPageState();
}

class _IncomingBookingsPageState extends State<IncomingBookingsPage> {
  /// Internal list of incoming booking requests. Each map contains
  /// an id, customer name, service title and the requested
  /// appointment date/time. When a request is accepted or declined
  /// it will be removed from this list.
  /// Incoming bookings loaded from the database. Each entry contains
  /// an id, customer name, service name and start time.
  List<Map<String, dynamic>> _incomingBookings = [];

  /// Indicates whether data is currently being loaded from the
  /// database. While loading, a progress indicator is shown.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadIncomingBookings();
  }

  /// Loads all pending bookings from the database. Queries the
  /// bookings table for rows with status 'pending' and joins the
  /// customers and services tables to get names. The resulting list
  /// contains maps with keys id, customer, service and datetime.
  Future<void> _loadIncomingBookings() async {
    setState(() {
      _loading = true;
    });
    try {
      final bookings = await DbService.getPendingBookings();
      setState(() {
        _incomingBookings = bookings;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Accepts a booking request. Updates the booking status to
  /// 'confirmed' in the database and removes it from the list.
  Future<void> _acceptBooking(int id) async {
    try {
      await DbService.confirmBooking(id);
      setState(() {
        _incomingBookings.removeWhere((b) => b['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buchung angenommen.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Aktualisieren der Buchung.')),
      );
    }
  }

  /// Declines a booking request. Opens the reschedule dialog and
  /// inserts suggested alternatives into the database. Each
  /// suggested date/time is stored in the `reschedule_suggestions`
  /// table. After sending suggestions, the booking remains pending
  /// until accepted or manually cancelled.
  Future<void> _declineBooking(Map<String, dynamic> booking) async {
    final result = await showDialog<List<Map<String, dynamic>?>>(
      context: context,
      builder: (context) => const RescheduleDialog(),
    );
    if (result != null) {
      try {
        final suggestions = <DateTime>[];
        for (final suggestion in result) {
          if (suggestion == null) continue;
          final dynamic dt = suggestion['datetime'];
          if (dt is DateTime) {
            suggestions.add(dt);
          }
        }
        await DbService.addRescheduleSuggestions(
            booking['id'] as int, suggestions);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Umbuchungsvorschlag gesendet.')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Senden des Vorschlags.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eingehende Buchungsanfragen'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _incomingBookings.isEmpty
              ? const Center(child: Text('Keine neuen Buchungsanfragen.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _incomingBookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = _incomingBookings[index];
                    final DateTime dateTime = booking['datetime'] as DateTime;
                    final String formattedDate =
                        '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
                    final String formattedTime =
                        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['customer'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking['service'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$formattedDate • $formattedTime',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _acceptBooking(booking['id'] as int),
                                  child: const Text('Annehmen'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _declineBooking(booking),
                                  child: const Text('Ablehnen'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}