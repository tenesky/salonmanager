import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/db_service.dart';

/// A page that shows a list of the customer's bookings.
///
/// All bookings are loaded from Supabase for the currently
/// authenticated user.  Users can filter by status, pick a
/// date range and search by Service name.  Tapping a card opens
/// a detailed view of the booking.  Swipe or use the delete icon
/// to cancel a booking.  This screen implements the
/// post‑wizard booking overview described in the specification
/// (Screen 25).  It replaces the previous local storage
/// implementation with a Supabase‑backed data source.
class BookingsListPage extends StatefulWidget {
  const BookingsListPage({Key? key}) : super(key: key);

  @override
  State<BookingsListPage> createState() => _BookingsListPageState();
}

class _BookingsListPageState extends State<BookingsListPage> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = false;
  String _statusFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!AuthService.isLoggedIn()) {
        Navigator.of(context).pushNamed('/login');
      } else {
        await _loadBookings();
      }
    });
  }

  /// Loads bookings from Supabase for the authenticated customer
  /// applying the current filters (status, date range, search).  If
  /// the user record cannot be found, an empty list is shown.
  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
    });
    final email = AuthService.currentUserEmail();
    if (email == null) {
      setState(() {
        _bookings = [];
        _loading = false;
      });
      return;
    }
    try {
      final customer = await DbService.getCustomerByEmail(email);
      if (customer == null) {
        setState(() {
          _bookings = [];
          _loading = false;
        });
        return;
      }
      final List<String>? statuses = _statusFilter == 'all'
          ? null
          : [_statusFilter];
      final bookings = await DbService.getBookingsForCustomer(
        customer['id'] as int,
        statuses: statuses,
        start: _startDate,
        end: _endDate,
        search: _search,
      );
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (e) {
      // Error retrieving bookings; show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Buchungen: $e')),
        );
      }
      setState(() {
        _bookings = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Buchungen'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter row
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _statusFilter,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Alle')),
                                DropdownMenuItem(value: 'pending', child: Text('Angefragt')),
                                DropdownMenuItem(value: 'confirmed', child: Text('Bestätigt')),
                                DropdownMenuItem(value: 'canceled', child: Text('Storniert')),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  _statusFilter = val;
                                });
                                _loadBookings();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Suche Service',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _search = val;
                                });
                                // Slight debounce by calling after frame
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _loadBookings();
                                });
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(now.year + 5),
                                initialDateRange: _startDate != null && _endDate != null
                                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                                    : null,
                              );
                              if (picked != null) {
                                setState(() {
                                  _startDate = picked.start;
                                  _endDate = picked.end;
                                });
                                _loadBookings();
                              }
                            },
                            icon: const Icon(Icons.date_range),
                            tooltip: 'Zeitraum wählen',
                          ),
                        ],
                      ),
                      if (_startDate != null && _endDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                'Zeitraum: ${DateFormat('dd.MM.yyyy').format(_startDate!)} – ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
                                style: TextStyle(color: theme.colorScheme.secondary),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _startDate = null;
                                    _endDate = null;
                                  });
                                  _loadBookings();
                                },
                                child: const Icon(Icons.clear, size: 18),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: _bookings.isEmpty
                      ? const Center(child: Text('Keine Buchungen gefunden.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _bookings.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            final DateTime dt = booking['datetime'] as DateTime;
                            final formattedDate = DateFormat('EEE, d. MMM yyyy', 'de_DE').format(dt);
                            final formattedTime = DateFormat('HH:mm').format(dt);
                            return Dismissible(
                              key: ValueKey(booking['id']),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (dir) async {
                                return await _confirmCancel(context, booking['id'] as int);
                              },
                              background: Container(
                                color: Colors.redAccent,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Card(
                                child: ListTile(
                                  leading: const Icon(Icons.event_note),
                                  title: Text(booking['serviceName'] ?? ''),
                                  subtitle: Text('$formattedDate • $formattedTime'),
                                  trailing: _buildStatusChip(booking['status'] as String?),
                                  onTap: () {
                                    // Navigate to booking detail page
                                    Navigator.of(context).pushNamed('/bookings/detail', arguments: {
                                      'id': booking['id'],
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// Builds a small chip representing the booking status.
  Widget _buildStatusChip(String? status) {
    final String text = status == 'pending'
        ? 'Angefragt'
        : status == 'confirmed'
            ? 'Bestätigt'
            : status == 'canceled'
                ? 'Storniert'
                : status ?? '';
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

  /// Shows a confirmation dialog before cancelling a booking.  If the
  /// user confirms, the booking is cancelled via [DbService.cancelBookings]
  /// and the list is reloaded.  Returns true if the item should be
  /// dismissed.
  Future<bool> _confirmCancel(BuildContext context, int bookingId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        String reason = '';
        String message = '';
        return AlertDialog(
          title: const Text('Buchung stornieren'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Möchtest du diese Buchung wirklich stornieren?'),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Grund'),
                onChanged: (val) => reason = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nachricht (optional)'),
                onChanged: (val) => message = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await DbService.cancelBookings(
                    ids: [bookingId],
                    reason: reason.isEmpty ? 'Kunde' : reason,
                    message: message,
                  );
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Buchung storniert')),
                  );
                  _loadBookings();
                } catch (e) {
                  Navigator.of(context).pop(false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Stornieren: $e')),
                  );
                }
              },
              child: const Text('Stornieren'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}