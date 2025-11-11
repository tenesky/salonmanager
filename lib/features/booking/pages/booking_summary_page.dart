import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final serviceId = prefs.getString('draft_service_id');
    final stylistId = prefs.getString('draft_stylist_id');
    final dateStr = prefs.getString('draft_date');
    final timeSlot = prefs.getString('draft_time_slot');
    final notes = prefs.getString('draft_notes');
    final imagePaths = prefs.getStringList('draft_image_paths');
    final paymentType = prefs.getString('draft_payment_type');
    final paymentMethod = prefs.getString('draft_payment_method');

    // Map salon ID to name using the static list from SalonListPage.
    String? salonName;
    if (salonId != null) {
      // Static salon list matching the IDs defined in BookingSelectSalonPage.
      final salons = [
        {'id': '1', 'name': 'Salon Elegance'},
        {'id': '2', 'name': 'Hair Couture'},
        {'id': '3', 'name': 'Golden Scissors'},
        {'id': '4', 'name': 'Style Studio'},
        {'id': '5', 'name': 'Beauty Bar'},
      ];
      final salon = salons.firstWhere((s) => s['id'] == salonId, orElse: () => {});
      salonName = salon['name'] as String?;
    }
    // Map service ID to details using the static list from BookingSelectServicePage.
    String? serviceTitle;
    String? servicePrice;
    String? serviceDuration;
    if (serviceId != null) {
      final services = [
        {
          'id': 'd1',
          'title': 'Damenhaarschnitt',
          'price': '€40–€60',
          'duration': '60 min',
        },
        {
          'id': 'd2',
          'title': 'Färben & Strähnen',
          'price': '€70–€120',
          'duration': '90 min',
        },
        {
          'id': 'h1',
          'title': 'Herrenhaarschnitt',
          'price': '€25–€40',
          'duration': '30 min',
        },
        {
          'id': 'h2',
          'title': 'Rasur & Bartpflege',
          'price': '€20–€35',
          'duration': '30 min',
        },
        {
          'id': 'b1',
          'title': 'Barttrimmen',
          'price': '€15–€25',
          'duration': '20 min',
        },
        {
          'id': 'b2',
          'title': 'Vollbartpflege',
          'price': '€25–€40',
          'duration': '30 min',
        },
        {
          'id': 's1',
          'title': 'Balayage',
          'price': '€120–€180',
          'duration': '120 min',
        },
        {
          'id': 's2',
          'title': 'Keratin‑Behandlung',
          'price': '€150–€200',
          'duration': '150 min',
        },
      ];
      final service = services.firstWhere((s) => s['id'] == serviceId, orElse: () => {});
      serviceTitle = service['title'] as String?;
      servicePrice = service['price'] as String?;
      serviceDuration = service['duration'] as String?;
    }
    // Map stylist ID to name using the static list from BookingSelectStylistPage.
    String? stylistName;
    if (stylistId != null) {
      final stylists = [
        {'id': 'auto', 'name': 'Automatisch zuweisen'},
        {'id': 's1', 'name': 'Lena Müller'},
        {'id': 's2', 'name': 'Maximilian Schröder'},
        {'id': 's3', 'name': 'Aylin Kaya'},
      ];
      final stylist = stylists.firstWhere((s) => s['id'] == stylistId, orElse: () => {});
      stylistName = stylist['name'] as String?;
    }
    // Format date/time.
    String? dateDisplay;
    String? timeDisplay;
    if (dateStr != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        dateDisplay = DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(date);
      }
    }
    if (timeSlot != null) {
      timeDisplay = timeSlot;
    }
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
      };
    });
  }

  /// Persists the current summary as a booking entry and clears
  /// draft values. Each booking is stored as a JSON string in a
  /// list under the key `bookings`. After storing the booking this
  /// method navigates to the success page.
  Future<void> _finaliseBooking() async {
    setState(() {
      _loading = true;
    });
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    // Retrieve existing bookings
    final existing = prefs.getStringList('bookings') ?? [];
    // Create a booking map with a timestamp as id
    final booking = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ..._summary,
      'status': 'confirmed',
    };
    existing.add(jsonEncode(booking));
    await prefs.setStringList('bookings', existing);
    // Clear draft keys
    for (final key in [
      'draft_salon_id',
      'draft_service_id',
      'draft_stylist_id',
      'draft_date',
      'draft_time_slot',
      'draft_notes',
      'draft_image_paths',
      'draft_payment_type',
      'draft_payment_method',
      'draft_payment_terms'
    ]) {
      await prefs.remove(key);
    }
    setState(() {
      _loading = false;
    });
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/booking/success');
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _loading ? null : _finaliseBooking,
          child: const Text('Buchen'),
        ),
      ),
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