import 'package:flutter/material.dart';
import 'dart:io';
import '../../../services/db_service.dart';
import 'package:intl/intl.dart';

/// Shows detailed information about a single booking.
///
/// The booking data is passed in via the route arguments as a
/// `Map<String, dynamic>`. Details such as salon, service, stylist,
/// date/time, notes, images and payment are displayed. This page
/// corresponds to the booking detail screen mentioned after the
/// booking wizard in the specification (Screens 24–27). Since those
/// screens are not fully specified, this implementation provides a
/// straightforward overview of the stored data.
class BookingDetailPage extends StatefulWidget {
  /// Either provide a [booking] map with all details or a [bookingId]
  /// to load the details from Supabase.  If [bookingId] is set, the
  /// [booking] parameter can be omitted.
  final Map<String, dynamic>? booking;
  final int? bookingId;

  const BookingDetailPage({Key? key, this.booking, this.bookingId})
      : assert(booking != null || bookingId != null),
        super(key: key);

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Map<String, dynamic>? _booking;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _booking = widget.booking;
    } else {
      _loadBooking();
    }
  }

  Future<void> _loadBooking() async {
    if (widget.bookingId == null) return;
    setState(() {
      _loading = true;
    });
    try {
      final details = await DbService.getBookingDetail(widget.bookingId!);
      setState(() {
        _booking = details;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imagePaths = (_booking?['imagePaths'] as List<dynamic>?)?.cast<String>() ?? [];
    final paymentType = _booking?['paymentType'];
    final paymentMethod = _booking?['paymentMethod'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buchungsdetails'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Keine Buchungsdaten gefunden.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDetailCard(
                        title: 'Service',
                        content: _booking?['serviceName'] ?? '–',
                        icon: Icons.design_services,
                      ),
                      _buildDetailCard(
                        title: 'Stylist',
                        content: _booking?['stylistName'] ?? '–',
                        icon: Icons.person,
                      ),
                      _buildDetailCard(
                        title: 'Datum & Uhrzeit',
                        content: () {
                          final dtVal = _booking?['start_datetime'];
                          if (dtVal == null) return '–';
                          DateTime dt;
                          if (dtVal is String) {
                            dt = DateTime.parse(dtVal).toLocal();
                          } else if (dtVal is DateTime) {
                            dt = dtVal.toLocal();
                          } else {
                            return '–';
                          }
                          final date = DateFormat('EEE, d. MMM yyyy', 'de_DE').format(dt);
                          final time = DateFormat('HH:mm').format(dt);
                          return '$date\n$time';
                        }(),
                        icon: Icons.event,
                      ),
                      if ((_booking?['notes'] ?? '').toString().isNotEmpty)
                        _buildDetailCard(
                          title: 'Notizen',
                          content: _booking?['notes'] ?? '',
                          icon: Icons.notes,
                        ),
                      if (imagePaths.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.image),
                                    SizedBox(width: 8),
                                    Text('Bilder',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imagePaths.length,
                                    itemBuilder: (context, index) {
                                      final path = imagePaths[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(path),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (paymentType != null || paymentMethod != null)
                        _buildDetailCard(
                          title: 'Zahlung',
                          content:
                              '${paymentType == 'voll' ? 'Komplettzahlung' : 'Anzahlung'}\n${paymentMethod == 'karte' ? 'Karte' : paymentMethod == 'wallet' ? 'Wallet' : paymentMethod == 'bar' ? 'Bar' : ''}',
                          icon: Icons.payment,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatusChip(_booking?['status'] as String?),
                          const SizedBox(width: 8),
                          const Text('Status'),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Builds a card used to display a single booking detail.
  Widget _buildDetailCard({required String title, required String content, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
      ),
    );
  }

  /// Builds a chip to display status in the detail view.
  Widget _buildStatusChip(String? status) {
    final String text = status == 'pending'
        ? 'Angefragt'
        : status == 'confirmed'
            ? 'Bestätigt'
            : 'Storniert';
    final Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.green;
        break;
      case 'canceled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}