import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fifth step of the booking wizard: select a time slot.  
///
/// After the customer has selected a date, this page displays a grid
/// of available times for that day. Each slot is marked as
/// "frei" (free), "belegt" (booked) or "gehalten" (held).  When a
/// free slot is tapped a soft‑hold countdown of two minutes starts
/// during which the slot appears held and is reserved for the user.
/// Once a slot is selected the “Weiter” button is enabled. The
/// selection is persisted in shared preferences as `draft_time_slot`.
/// This implementation follows the screen specification for Wizard
/// steps 4–5【522868310347694†L150-L159】.
class BookingSelectTimePage extends StatefulWidget {
  const BookingSelectTimePage({Key? key}) : super(key: key);

  @override
  State<BookingSelectTimePage> createState() => _BookingSelectTimePageState();
}

class _BookingSelectTimePageState extends State<BookingSelectTimePage> {
  DateTime? _selectedDate;
  List<Map<String, String>> _slots = [];
  String? _selectedTime;
  Timer? _holdTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadDraftDate();
    _initSlots();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDraftDate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('draft_date');
    if (stored != null) {
      try {
        setState(() {
          _selectedDate = DateTime.parse(stored);
        });
      } catch (_) {
        // ignore parse errors
      }
    }
  }

  /// Initialize sample times and statuses. In a real app this would
  /// call the availability API for the selected date【522868310347694†L155-L160】.
  void _initSlots() {
    final times = <String>[];
    for (int hour = 9; hour <= 17; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        times.add(time);
      }
    }
    setState(() {
      _slots = times.map((t) {
        String status = 'frei';
        // Mark some demo slots as booked
        if (t == '10:30' || t == '13:00' || t == '15:30') {
          status = 'belegt';
        }
        return {'time': t, 'status': status};
      }).toList();
    });
  }

  /// Start a soft hold countdown for the selected slot.
  void _startHoldCountdown() {
    _holdTimer?.cancel();
    setState(() {
      _remainingSeconds = 2 * 60; // two minutes
    });
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        // Release hold
        _releaseHold();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  /// Release the hold on the selected slot when the timer expires or
  /// when the user changes their selection.
  void _releaseHold() {
    if (_selectedTime != null) {
      final index = _slots.indexWhere((slot) => slot['time'] == _selectedTime);
      if (index >= 0) {
        _slots[index] = {'time': _slots[index]['time']!, 'status': 'frei'};
      }
    }
    setState(() {
      _selectedTime = null;
      _remainingSeconds = 0;
    });
  }

  /// Handles selection of a timeslot. Only free slots can be selected.
  Future<void> _selectSlot(int index) async {
    final slot = _slots[index];
    if (slot['status'] != 'frei') return;
    // If another slot is held, release it first
    if (_selectedTime != null) {
      _releaseHold();
    }
    // Mark as held
    setState(() {
      _selectedTime = slot['time'];
      _slots[index] = {'time': slot['time']!, 'status': 'gehalten'};
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_time_slot', slot['time']!);
    _startHoldCountdown();
  }

  /// Format the selected date for display.
  String _formatSelectedDate() {
    if (_selectedDate == null) return '';
    final formatter = DateFormat('EEEE, d. MMMM yyyy', 'de_DE');
    return formatter.format(_selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uhrzeit wählen'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 5 / 8,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('5/8'),
              ],
            ),
          ),
          // Selected date display
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                _formatSelectedDate(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          // Timeslots grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                ),
                itemCount: _slots.length,
                itemBuilder: (context, index) {
                  final slot = _slots[index];
                  final status = slot['status'];
                  final isSelected = _selectedTime == slot['time'];
                  Color borderColor;
                  Color backgroundColor;
                  // Allow the text color to be nullable because the default
                  // case assigns null to it when the slot is not selected.
                  Color? textColor;
                  switch (status) {
                    case 'belegt':
                      borderColor = Colors.grey;
                      backgroundColor = Colors.grey.shade200;
                      textColor = Colors.grey;
                      break;
                    case 'gehalten':
                      borderColor = Theme.of(context).colorScheme.secondary;
                      backgroundColor = Theme.of(context).colorScheme.secondary.withOpacity(0.2);
                      textColor = Theme.of(context).colorScheme.secondary;
                      break;
                    default:
                      borderColor = isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor;
                      backgroundColor = isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Colors.transparent;
                      textColor = isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null;
                  }
                  return GestureDetector(
                    onTap: () => _selectSlot(index),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        slot['time']!,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Countdown display if holding
          if (_remainingSeconds > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_bottom),
                  const SizedBox(width: 8),
                  Text(
                    'Slot wird ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')} reserviert',
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _releaseHold,
                    child: const Text('Abbrechen'),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedTime != null
              ? () {
                  Navigator.of(context).pushNamed('/booking/additional-info');
                }
              : null,
          child: const Text('Weiter'),
        ),
      ),
    );
  }
}