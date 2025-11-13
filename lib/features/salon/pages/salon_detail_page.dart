import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/salon.dart';

/// Detail view for a salon. In addition to the standard salon
/// information (services, team and contact details) this page
/// includes a mini‑calendar and time slot picker to allow a
/// customer to quickly book an appointment at this salon. When the
/// “Jetzt buchen” button is tapped, the selected date and time are
/// saved to shared preferences under the keys `draft_date` and
/// `draft_time_slot` so that the booking wizard can prefill these
/// values. The user is then navigated directly to the service
/// selection step of the booking flow (step 2)【522868310347694†L150-L156】.
class SalonDetailPage extends StatefulWidget {
  final Salon salon;

  const SalonDetailPage({Key? key, required this.salon}) : super(key: key);

  @override
  _SalonDetailPageState createState() => _SalonDetailPageState();
}

class _SalonDetailPageState extends State<SalonDetailPage> {
  late DateTime _selectedDate;
  late List<DateTime> _nextSevenDays;
  final List<String> _defaultTimeslots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
  ];
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Initialise with today as the selected date and compute the
    // next seven days. Strip the time portion so comparison works.
    _selectedDate = DateTime(now.year, now.month, now.day);
    _nextSevenDays = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  /// Handles quick booking. Validates that a time has been selected,
  /// persists the date and time to shared preferences and then
  /// navigates to the service selection screen. If no time is
  /// selected a short message prompts the user to choose one.
  Future<void> _quickBook() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wählen Sie eine Uhrzeit.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_date', _selectedDate.toIso8601String());
    await prefs.setString('draft_time_slot', _selectedTime!);
    if (context.mounted) {
      Navigator.of(context).pushNamed('/booking/select-service');
    }
  }

  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;
    // Static demo data for services and team. In a real app these
    // would come from the backend for the given salon.
    final services = [
      {'title': 'Haarschnitt', 'price': '45 €', 'duration': '60 min'},
      {'title': 'Färben', 'price': '70 €', 'duration': '90 min'},
      {'title': 'Bart trimmen', 'price': '20 €', 'duration': '30 min'},
    ];
    final team = [
      {'name': 'Anna', 'image': 'assets/icon_cropped.png'},
      {'name': 'Paul', 'image': 'assets/icon_cropped2.png'},
      {'name': 'Lisa', 'image': 'assets/icon_manual_crop.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(salon.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero area: cover image with logo overlay
            Stack(
              children: [
                Image.asset(
                  salon.coverImage,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(salon.logoImage),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salon.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(salon.address)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Öffnungszeiten: ${salon.openingHours}')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(salon.phone)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quick appointment picker section
                  Text(
                    'Schnell einen Termin buchen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildDatePicker(),
                  const SizedBox(height: 8),
                  _buildTimeSlots(),
                  const SizedBox(height: 24),
                  // Services list
                  Text(
                    'Leistungen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: services
                        .map(
                          (service) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service['title'] as String),
                            subtitle: Text(service['duration'] as String),
                            trailing: Text(service['price'] as String),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  // Team section
                  Text(
                    'Unser Team',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: team
                        .map(
                          (member) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                backgroundImage: AssetImage(member['image'] as String),
                              ),
                              const SizedBox(height: 4),
                              Text(member['name'] as String),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _quickBook,
                      child: const Text('Jetzt buchen'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a horizontal date picker showing the next seven days. The
  /// selected date is highlighted. Selecting a date updates
  /// [_selectedDate] and resets the selected time.
  Widget _buildDatePicker() {
    final dateFormat = DateFormat('EEE dd.MM', 'de_DE');
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _nextSevenDays.length,
        itemBuilder: (context, index) {
          final date = _nextSevenDays[index];
          final bool isSelected = _selectedDate == date;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(dateFormat.format(date)),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedDate = date;
                  _selectedTime = null;
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds a simple list of time slots. The selected slot is
  /// highlighted. Selecting a slot updates [_selectedTime].
  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _defaultTimeslots.map((t) {
        final bool isSelected = _selectedTime == t;
        return ChoiceChip(
          label: Text(t),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedTime = t;
            });
          },
        );
      }).toList(),
    );
  }
}