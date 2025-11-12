import 'package:flutter/material.dart';
import '../../../services/db_service.dart';
import 'package:intl/intl.dart';

/// Displays a success message after a booking has been completed.
///
/// This page appears after the booking summary and shows a large
/// confirmation icon, a short message, and actions to add the
/// appointment to the calendar or view existing bookings. The
/// implementation loosely follows the description of the
/// success/confirmation screen in the specification for Wizard 8
/// (Erfolg)【522868310347694†L176-L183】.
class BookingSuccessPage extends StatefulWidget {
  /// Optional booking id to load details for this success page.  If
  /// provided the page will display the booked service, date and
  /// price.  Otherwise a generic success message is shown.
  final int? bookingId;
  const BookingSuccessPage({Key? key, this.bookingId}) : super(key: key);

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> {
  Map<String, dynamic>? _booking;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    if (widget.bookingId == null) return;
    setState(() {
      _loading = true;
    });
    try {
      final booking = await DbService.getBookingDetail(widget.bookingId!);
      setState(() {
        _booking = booking;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Builds a human‑readable details string from a booking map.  The
  /// returned string includes the date/time, service name and price.
  String _buildDetailsString(Map<String, dynamic> booking) {
    String details = '';
    // Start datetime
    final startIso = booking['start_datetime'];
    if (startIso is String) {
      final dt = DateTime.parse(startIso).toLocal();
      final formattedDate = DateFormat('EEE, d. MMM yyyy', 'de_DE').format(dt);
      final formattedTime = DateFormat('HH:mm').format(dt);
      details += 'Datum: $formattedDate\nUhrzeit: $formattedTime';
    }
    // Service name: handle both a single service map and a list of services.
    String? serviceName;
    final svc = booking['services'];
    if (svc is Map) {
      // Legacy format: services as a map
      serviceName = svc['name'] as String?;
    } else if (svc is List && svc.isNotEmpty) {
      final firstSvc = svc.first;
      if (firstSvc is Map<String, dynamic> && firstSvc.containsKey('name')) {
        serviceName = firstSvc['name'] as String?;
      }
    } else if (booking.containsKey('serviceName')) {
      serviceName = booking['serviceName'] as String?;
    }
    if (serviceName != null) {
      details += '\nLeistung: $serviceName';
    }
    // Price
    final price = booking['price'];
    if (price != null) {
      final priceNum = price is num
          ? price
          : (price is String ? double.tryParse(price) ?? 0 : 0);
      details += '\nPreis: ${priceNum.toStringAsFixed(2)} €';
    }
    return details;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erfolg'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 96, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                const Text(
                  'Termin gebucht!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const CircularProgressIndicator()
                else if (_booking != null) ...[
                  Text(
                    // Format details
                    _buildDetailsString(_booking!),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Text(
                    'Dein Termin wurde erfolgreich gebucht.\nWir haben eine Bestätigung per E‑Mail gesendet.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Placeholder for calendar integration
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Zum Kalender hinzugefügt')),
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('In Kalender speichern'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    // Navigate to the bookings overview in the profile
                    Navigator.of(context).pushNamed('/profile/bookings');
                  },
                  child: const Text('Zum Profil'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/home');
                  },
                  child: const Text('Startseite'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}