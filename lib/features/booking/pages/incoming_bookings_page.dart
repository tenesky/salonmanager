import 'package:flutter/material.dart';
import '../widgets/reschedule_dialog.dart';

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
  final List<Map<String, dynamic>> _incomingBookings = [
    {
      'id': 1,
      'customer': 'Anna Schmidt',
      'service': 'Haarschnitt (Damen)',
      'datetime': DateTime(2025, 11, 14, 10, 30),
    },
    {
      'id': 2,
      'customer': 'Max Müller',
      'service': 'Herrenhaarschnitt',
      'datetime': DateTime(2025, 11, 14, 12, 0),
    },
    {
      'id': 3,
      'customer': 'Sofia Becker',
      'service': 'Balayage & Styling',
      'datetime': DateTime(2025, 11, 15, 9, 0),
    },
  ];

  /// Accepts a booking request. This removes the booking from the
  /// incoming list and shows a brief confirmation via a snackbar.
  void _acceptBooking(int id) {
    setState(() {
      _incomingBookings.removeWhere((booking) => booking['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buchung angenommen.')),
    );
  }

  /// Declines a booking request by opening the reschedule dialog.
  /// The stylist can select up to three alternative date/time
  /// combinations. Once proposals are submitted a confirmation
  /// snackbar is shown. The booking remains in the list for now.
  Future<void> _declineBooking(Map<String, dynamic> booking) async {
    final result = await showDialog<List<Map<String, dynamic>?>>(
      context: context,
      builder: (context) => const RescheduleDialog(),
    );
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Umbuchungsvorschlag gesendet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eingehende Buchungsanfragen'),
      ),
      body: _incomingBookings.isEmpty
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