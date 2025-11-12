import 'package:flutter/material.dart';
import 'dart:io';

/// Shows detailed information about a single booking.
///
/// The booking data is passed in via the route arguments as a
/// `Map<String, dynamic>`. Details such as salon, service, stylist,
/// date/time, notes, images and payment are displayed. This page
/// corresponds to the booking detail screen mentioned after the
/// booking wizard in the specification (Screens 24–27). Since those
/// screens are not fully specified, this implementation provides a
/// straightforward overview of the stored data.
class BookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailPage({Key? key, required this.booking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> imagePaths = (booking['imagePaths'] as List<dynamic>?)?.cast<String>() ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buchungsdetails'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDetailCard(title: 'Salon', content: booking['salonName'] ?? '–', icon: Icons.store),
            _buildDetailCard(
              title: 'Leistung',
              content:
                  '${booking['serviceTitle'] ?? '–'}\n${booking['servicePrice'] ?? ''} • ${booking['serviceDuration'] ?? ''}',
              icon: Icons.design_services,
            ),
            _buildDetailCard(title: 'Stylist', content: booking['stylistName'] ?? '–', icon: Icons.person),
            _buildDetailCard(
              title: 'Datum & Uhrzeit',
              content: '${booking['date'] ?? ''}\n${booking['time'] ?? ''}',
              icon: Icons.event,
            ),
            if ((booking['notes'] ?? '').toString().isNotEmpty)
              _buildDetailCard(title: 'Notizen', content: booking['notes'], icon: Icons.notes),
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
                          Text('Bilder', style: TextStyle(fontWeight: FontWeight.bold)),
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
            _buildDetailCard(
              title: 'Zahlung',
              content:
                  '${booking['paymentType'] == 'voll' ? 'Komplettzahlung' : 'Anzahlung'}\n${booking['paymentMethod'] == 'karte' ? 'Karte' : booking['paymentMethod'] == 'wallet' ? 'Wallet' : booking['paymentMethod'] == 'bar' ? 'Bar' : ''}',
              icon: Icons.payment,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusChip(booking['status'] as String?),
                const SizedBox(width: 8),
                Text('Status'),
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
      case 'cancelled':
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