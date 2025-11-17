import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDraftDate();
    // Timeslots will be loaded once the selected date is known.
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
        final parsed = DateTime.parse(stored);
        setState(() {
          _selectedDate = parsed;
        });
      } catch (_) {
        // ignore parse errors
      }
    }
    // After loading the date, load the available timeslots
    if (_selectedDate != null) {
      await _loadTimeslots();
    }
  }

  /// Initialize sample times and statuses. In a real app this would
  /// call the availability API for the selected date【522868310347694†L155-L160】.
  Future<void> _loadTimeslots() async {
    if (_selectedDate == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final stylistStr = prefs.getString('draft_stylist_id');
      int? stylistId;
      if (stylistStr != null && stylistStr.isNotEmpty && stylistStr != '0') {
        stylistId = int.tryParse(stylistStr);
      }
      // Load shifts and bookings for the selected date from Supabase.
      final shifts = await DbService.getShiftsForDate(_selectedDate!, stylistId: stylistId);
      final bookings = await DbService.getBookingsForDate(_selectedDate!, stylistId: stylistId);
      // Determine the time range for the grid.  If no shifts are
      // available, the slot list remains empty.
      if (shifts.isEmpty) {
        setState(() {
          _slots = [];
          _isLoading = false;
        });
        return;
      }
      // Compute the earliest start and latest end among shifts.
      DateTime earliest = shifts.first['start'] as DateTime;
      DateTime latest = shifts.first['end'] as DateTime;
      for (final s in shifts) {
        final sStart = s['start'] as DateTime;
        final sEnd = s['end'] as DateTime;
        if (sStart.isBefore(earliest)) earliest = sStart;
        if (sEnd.isAfter(latest)) latest = sEnd;
      }
      // Generate 30‑minute slots between earliest and latest.
      final List<Map<String, String>> slots = [];
      DateTime current = earliest;
      while (!current.isAfter(latest.subtract(const Duration(minutes: 30)))) {
        final next = current.add(const Duration(minutes: 30));
        // Determine status: free if at least one stylist has this slot
        // within a shift and not booked; otherwise booked.
        bool available = false;
        if (stylistId != null) {
          // Only check the single stylist
          for (final s in shifts.where((sh) => sh['stylist_id'] == stylistId)) {
            final start = s['start'] as DateTime;
            final end = s['end'] as DateTime;
            if (current.isAtSameMomentAs(start) || (current.isAfter(start) && current.isBefore(end))) {
              // Within shift range
              // Check if there is a booking overlapping this slot for this stylist
              final hasBooking = bookings.any((b) {
                final bStart = b['start'] as DateTime;
                final bEnd = b['end'] as DateTime;
                return (current.isBefore(bEnd) && next.isAfter(bStart));
              });
              if (!hasBooking) {
                available = true;
                break;
              }
            }
          }
        } else {
          // Beliebig: free if any stylist has this slot within shift and not booked
          for (final s in shifts) {
            final start = s['start'] as DateTime;
            final end = s['end'] as DateTime;
            if (current.isAtSameMomentAs(start) || (current.isAfter(start) && current.isBefore(end))) {
              // Within shift
              final sid = s['stylist_id'] as int?;
              // Find bookings for this stylist
              final hasBooking = bookings.any((b) {
                final bStart = b['start'] as DateTime;
                final bEnd = b['end'] as DateTime;
                if (stylistId != null && b['stylist_id'] != stylistId) return false;
                return (current.isBefore(bEnd) && next.isAfter(bStart) && (b['stylist_id'] == sid));
              });
              if (!hasBooking) {
                available = true;
                break;
              }
            }
          }
        }
        slots.add({'time': DateFormat('HH:mm').format(current), 'status': available ? 'frei' : 'belegt'});
        current = next;
      }
      setState(() {
        _slots = slots;
      });
    } catch (e) {
      // On error, show no slots.  In a real app, you might show an
      // error message to the user.
      setState(() {
        _slots = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          // Timeslots grid or loading indicator
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
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
          // Continue button within page body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTime != null
                    ? () {
                        Navigator.of(context).pushNamed('/booking/additional-info');
                      }
                    : null,
                child: const Text('Weiter'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, currentIndex: 2),
    );
  }

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
}