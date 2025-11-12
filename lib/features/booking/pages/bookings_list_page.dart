import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import the AuthService to enforce authentication before showing
// the bookings list.  The relative path climbs three directories
// (pages → booking → features → lib) to reach lib/services.
import '../../../services/auth_service.dart';

/// A page that shows a list of the user's bookings.
///
/// Each booking is loaded from local storage and displayed as a
/// card with the salon and service name, the scheduled date and
/// time, and a status chip. Tapping a card opens a detailed view
/// of the booking. This corresponds to the post‑wizard booking list
/// described in the specification (Screens 24–27). Since those
/// screens are not fully detailed in the document, this page
/// provides a basic implementation with sample status chips and
/// persistence via shared preferences.
class BookingsListPage extends StatefulWidget {
  const BookingsListPage({Key? key}) : super(key: key);

  @override
  State<BookingsListPage> createState() => _BookingsListPageState();
}

class _BookingsListPageState extends State<BookingsListPage> {
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _loadBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('bookings') ?? [];
    setState(() {
      _bookings = stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      // Sort by date descending
      _bookings.sort((a, b) {
        final aDate = _parseBookingDateTime(a);
        final bDate = _parseBookingDateTime(b);
        return bDate.compareTo(aDate);
      });
    });
  }

  /// Checks whether a user is authenticated before loading bookings.
  /// If no valid token exists the user is prompted to log in and
  /// redirected to the login page.  Otherwise the bookings are
  /// loaded from local storage.
  Future<void> _checkAuthentication() async {
    final isLoggedIn = AuthService().isLoggedIn;
    if (!isLoggedIn) {
      // Not logged in – show a message and navigate to login.
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bitte anmelden oder registrieren, um Ihre Buchungen zu sehen.'),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        });
      }
    } else {
      // Logged in – proceed to load bookings.
      await _loadBookings();
    }
  }

  /// Parses the combined date and time fields into a DateTime object.
  DateTime _parseBookingDateTime(Map<String, dynamic> booking) {
    final dateStr = booking['date'] as String?;
    final timeStr = booking['time'] as String?;
    if (dateStr == null || timeStr == null) return DateTime.now();
    try {
      final date = DateFormat('EEEE, d. MMMM yyyy', 'de_DE').parse(dateStr);
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Buchungen'),
      ),
      body: _bookings.isEmpty
          ? const Center(child: Text('Keine Buchungen gefunden.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: _bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_note),
                    title: Text('${booking['salonName'] ?? ''} – ${booking['serviceTitle'] ?? ''}'),
                    subtitle: Text('${booking['date']} • ${booking['time']}'),
                    trailing: _buildStatusChip(booking['status'] as String?),
                    onTap: () {
                      Navigator.of(context).pushNamed('/bookings/detail', arguments: booking);
                    },
                  ),
                );
              },
            ),
    );
  }

  /// Builds a small chip representing the booking status.
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