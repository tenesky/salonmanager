import 'package:flutter/material.dart';
import '../models/salon.dart';

/// Detail view for a salon. Displays basic information about the salon
/// and provides a quick booking option via a bottom sheet. The
/// bottom sheet contains a mini‑calendar and a time slot picker, and
/// a CTA that navigates to the booking wizard step 1. This
/// corresponds to the „Salon‑Schnellwahl“ screen (Modul B, Screen 14).
class SalonDetailPage extends StatefulWidget {
  final Salon salon;

  const SalonDetailPage({Key? key, required this.salon}) : super(key: key);

  @override
  State<SalonDetailPage> createState() => _SalonDetailPageState();
}

class _SalonDetailPageState extends State<SalonDetailPage> {
  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;
    return Scaffold(
      appBar: AppBar(
        title: Text(salon.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image with logo overlay
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openQuickBooking,
                      child: const Text('Schnell buchen'),
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

  /// Opens a bottom sheet allowing the user to quickly select a date
  /// and time for a booking. Once both a day and a time are chosen,
  /// the "Zum Booking‑Wizard" button navigates to the first step of
  /// the booking process. This implements the mini‑calendar and
  /// timeslot picker required for Screen 14. For now the wizard page
  /// is a placeholder.
  void _openQuickBooking() {
    // Set up local variables to persist selection state inside the
    // bottom sheet. They are defined outside the builder so they
    // persist across rebuilds triggered by setModalState.
    int selectedDayIndex = -1;
    int selectedTimeIndex = -1;
    // Generate a list of 7 dates starting from today
    final today = DateTime.now();
    final days = List<DateTime>.generate(7, (i) => today.add(Duration(days: i)));
    // Define sample time slots
    final times = [
      '09:00', '09:30', '10:00', '10:30', '11:00', '13:00', '14:00', '15:30', '17:00'
    ];
    // Helper to format dates for chips
    String formatDate(DateTime date) {
      const weekdayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      final day = weekdayNames[date.weekday - 1];
      final month = date.month.toString().padLeft(2, '0');
      final dayNum = date.day.toString().padLeft(2, '0');
      return '$day $dayNum.$month';
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Schnell buchen',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mini calendar (horizontal list of ChoiceChips)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(days.length, (index) {
                        final date = days[index];
                        final isSelected = selectedDayIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(formatDate(date)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedDayIndex = index;
                                } else {
                                  selectedDayIndex = -1;
                                }
                                // Reset time selection when day changes
                                selectedTimeIndex = -1;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedDayIndex >= 0) ...[
                    const Text(
                      'Zeit auswählen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(times.length, (i) {
                        final isSelected = selectedTimeIndex == i;
                        return ChoiceChip(
                          label: Text(times[i]),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedTimeIndex = i;
                              } else {
                                selectedTimeIndex = -1;
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (selectedDayIndex >= 0 && selectedTimeIndex >= 0)
                          ? () {
                              Navigator.pop(context);
                              Navigator.of(context).pushNamed('/booking/select-salon');
                            }
                          : null,
                      child: const Text('Zum Booking‑Wizard'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}