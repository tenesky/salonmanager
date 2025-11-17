import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';


/// Eighth step of the booking wizard: summary & booking confirmation.
///
/// On this page the user reviews all selections from the previous
/// wizard steps – salon, service, stylist, date/time, additional
/// notes/images and payment information – before finalising the
/// booking. Review cards display the collected data together with a
/// hint about the cancellation period. When the "Buchen" button is
/// pressed a loading overlay appears, the booking is stored locally
/// and the draft data is cleared. Afterwards the user is redirected
/// to a success page. This implementation follows the
/// specification for Wizard 8【522868310347694†L176-L183】.
class BookingSummaryPage extends StatefulWidget {
  const BookingSummaryPage({Key? key}) : super(key: key);

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  Map<String, dynamic> _summary = {};
  bool _loading = false;
  bool _acceptedTerms = true;

  /// Builds the persistent bottom navigation bar used throughout the app.
  /// [currentIndex] indicates the active tab. For booking pages we use index 2.
  Widget _buildBottomNav(BuildContext context, {required int currentIndex}) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: accent,
      unselectedItemColor:
          brightness == Brightness.dark ? Colors.white70 : Colors.black54,
      backgroundColor:
          brightness == Brightness.dark ? Colors.black : Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Galerie'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Buchen'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Termine'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            break;
          case 1:
            Navigator.of(context).pushNamed('/gallery');
            break;
          case 2:
            Navigator.of(context).pushNamed('/booking/select-salon');
            break;
          case 3:
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/profile/bookings');
            }
            break;
          case 4:
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/settings/profile');
            }
            break;
        }
      },
    );
  }

  double _totalPrice = 0;
  int _totalDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  /// Loads the booking draft data from shared preferences and maps
  /// the IDs to display names using the static lists defined in
  /// earlier wizard pages. If a field is missing the value remains
  /// null so the UI can handle it gracefully.
  Future<void> _loadSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final salonId = prefs.getString('draft_salon_id');
    final List<String>? serviceIds = prefs.getStringList('draft_service_ids');
    final stylistId = prefs.getString('draft_stylist_id');
    final dateStr = prefs.getString('draft_date');
    final timeSlot = prefs.getString('draft_time_slot');
    final notes = prefs.getString('draft_notes');
    final imagePaths = prefs.getStringList('draft_image_paths');
    final paymentType = prefs.getString('draft_payment_type');
    final paymentMethod = prefs.getString('draft_payment_method');
    final paymentDeposit = prefs.getString('draft_payment_deposit');
    // Resolve salon name
    String? salonName;
    if (salonId != null && salonId.isNotEmpty) {
      final parsedId = int.tryParse(salonId);
      if (parsedId != null) {
        final salon = await DbService.getSalonById(parsedId);
        salonName = salon?['name'] as String?;
      }
    }
    // Resolve services: names and aggregate price/duration
    String? serviceTitle;
    String? servicePrice;
    String? serviceDuration;
    double totalPrice = 0;
    int totalDuration = 0;
    List<Map<String, dynamic>> services = await DbService.getServices();
    List<String> selectedNames = [];
    if (serviceIds != null && serviceIds.isNotEmpty) {
      final idsInt = serviceIds.map((id) => int.tryParse(id)).whereType<int>().toList();
      for (final sid in idsInt) {
        final svc = services.firstWhere((s) => s['id'] == sid, orElse: () => {});
        if (svc.isNotEmpty) {
          selectedNames.add(svc['name'] as String);
          final dur = svc['duration'] as int? ?? 0;
          final price = svc['price'];
          totalDuration += dur;
          if (price is num) {
            totalPrice += price.toDouble();
          } else if (price is String) {
            totalPrice += double.tryParse(price) ?? 0;
          }
        }
      }
      if (selectedNames.isNotEmpty) {
        serviceTitle = selectedNames.join(', ');
        servicePrice = '${totalPrice.toStringAsFixed(2)} €';
        serviceDuration = '${totalDuration.toString()} Min';
      }
    }
    // Resolve stylist name
    String? stylistName;
    int? stylistIdParsed;
    if (stylistId != null && stylistId.isNotEmpty && stylistId != 'auto') {
      stylistIdParsed = int.tryParse(stylistId);
      if (stylistIdParsed != null) {
        try {
          final stylists = await DbService.getStylists();
          final st = stylists.firstWhere((s) => s['id'] == stylistIdParsed,
              orElse: () => {});
          if (st.isNotEmpty) {
            stylistName = st['name'] as String?;
          }
        } catch (_) {}
      }
    } else {
      stylistName = 'Beliebig';
    }
    // Format date/time
    String? dateDisplay;
    String? timeDisplay;
    DateTime? startDate;
    if (dateStr != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        dateDisplay = DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(date);
        startDate = date;
      }
    }
    if (timeSlot != null) {
      timeDisplay = timeSlot;
      if (startDate != null) {
        // parse time into startDate for later use
        final parts = timeSlot.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            startDate = DateTime(startDate.year, startDate.month, startDate.day, hour, minute);
          }
        }
      }
    }
    // Save totals to state
    _totalPrice = totalPrice;
    _totalDuration = totalDuration;
    setState(() {
      _summary = {
        'salonName': salonName,
        'serviceTitle': serviceTitle,
        'servicePrice': servicePrice,
        'serviceDuration': serviceDuration,
        'stylistName': stylistName,
        'date': dateDisplay,
        'time': timeDisplay,
        'notes': notes,
        'imagePaths': imagePaths ?? [],
        'paymentType': paymentType,
        'paymentMethod': paymentMethod,
        'paymentDeposit': paymentDeposit,
        'startDateTime': startDate?.toIso8601String(),
        'serviceIds': serviceIds,
        'stylistId': stylistIdParsed,
      };
    });
  }

  /// Persists the current summary as a booking entry and clears
  /// draft values. Each booking is stored as a JSON string in a
  /// list under the key `bookings`. After storing the booking this
  /// method navigates to the success page.
  Future<void> _finaliseBooking() async {
    if (!_acceptedTerms) {
      // Require acceptance of terms before proceeding
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bitte akzeptieren Sie die AGB/DSGVO-Bedingungen.'),
      ));
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      // Determine customer from logged-in user
      final email = AuthService.currentUserEmail();
      int? customerId;
      if (email != null) {
        final customer = await DbService.getCustomerByEmail(email);
        if (customer != null) {
          customerId = customer['id'] as int?;
        }
      }
      // Parse stylist
      int? stylistId;
      final sid = _summary['stylistId'];
      if (sid is int) {
        stylistId = sid;
      }
      // Service IDs
      final List<String>? serviceIds = (_summary['serviceIds'] as List?)?.cast<String>();
      int? primaryServiceId;
      if (serviceIds != null && serviceIds.isNotEmpty) {
        primaryServiceId = int.tryParse(serviceIds.first);
      }
      // Start datetime
      DateTime? startDt;
      final startIso = _summary['startDateTime'] as String?;
      if (startIso != null) {
        startDt = DateTime.tryParse(startIso);
      }
      // Notes: include notes and payment deposit if present
      String combinedNotes = '';
      final notes = _summary['notes'] as String?;
      if (notes != null && notes.isNotEmpty) {
        combinedNotes += notes;
      }
      final deposit = _summary['paymentDeposit'] as String?;
      if (deposit != null && deposit.isNotEmpty) {
        if (combinedNotes.isNotEmpty) combinedNotes += '\n';
        combinedNotes += 'Anzahlung: $deposit';
      }
      if (primaryServiceId == null || startDt == null) {
        throw Exception('Fehlende Daten');
      }
      final bookingId = await DbService.createBooking(
        customerId: customerId,
        stylistId: stylistId,
        serviceId: primaryServiceId,
        startDateTime: startDt,
        duration: _totalDuration,
        price: _totalPrice,
        notes: combinedNotes,
        status: 'pending',
      );
      // Clear draft values after successful creation
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'draft_salon_id',
        'draft_service_ids',
        'draft_stylist_id',
        'draft_date',
        'draft_time_slot',
        'draft_notes',
        'draft_image_paths',
        'draft_payment_type',
        'draft_payment_method',
        'draft_payment_deposit'
      ]) {
        await prefs.remove(key);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      Navigator.of(context).pushReplacementNamed(
        '/booking/success',
        arguments: bookingId,
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fehler beim Speichern der Buchung: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zusammenfassung'),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator 8/8
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 8 / 8,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('8/8'),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildReviewCard(
                        title: 'Salon',
                        content: _summary['salonName'] ?? '–',
                        icon: Icons.store,
                      ),
                      _buildReviewCard(
                        title: 'Leistung',
                        content:
                            '${_summary['serviceTitle'] ?? '–'}\n${_summary['servicePrice'] ?? ''} • ${_summary['serviceDuration'] ?? ''}',
                        icon: Icons.design_services,
                      ),
                      _buildReviewCard(
                        title: 'Stylist',
                        content: _summary['stylistName'] ?? '–',
                        icon: Icons.person,
                      ),
                      _buildReviewCard(
                        title: 'Datum & Uhrzeit',
                        content:
                            '${_summary['date'] ?? ''}\n${_summary['time'] ?? ''}',
                        icon: Icons.event,
                      ),
                      if ((_summary['notes'] ?? '').toString().isNotEmpty)
                        _buildReviewCard(
                          title: 'Notizen',
                          content: _summary['notes'],
                          icon: Icons.notes,
                        ),
                      if ((_summary['imagePaths'] as List).isNotEmpty)
                        _buildReviewCard(
                          title: 'Bilder',
                          content: '${(_summary['imagePaths'] as List).length} ausgewählt',
                          icon: Icons.image,
                        ),
                      _buildReviewCard(
                        title: 'Zahlung',
                        content:
                            '${_summary['paymentType'] == 'voll' ? 'Komplettzahlung' : 'Anzahlung'}\n${_summary['paymentMethod'] == 'karte' ? 'Karte' : _summary['paymentMethod'] == 'wallet' ? 'Wallet' : _summary['paymentMethod'] == 'bar' ? 'Bar' : ''}',
                        icon: Icons.payment,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Stornofrist: bis 24 Stunden vor dem Termin kostenlos stornierbar.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      // Terms and conditions acceptance
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (val) {
                              setState(() {
                                _acceptedTerms = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Ich akzeptiere die Allgemeinen Geschäftsbedingungen und die Datenschutzerklärung.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_loading || !_acceptedTerms) ? null : _finaliseBooking,
                            child: const Text('Buchen'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Buchung wird verarbeitet...'),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, currentIndex: 2),
    );
  }

  /// Builds a simple card to display a summary item with an icon and text.
  Widget _buildReviewCard({required String title, required String content, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
      ),
    );
  }
}