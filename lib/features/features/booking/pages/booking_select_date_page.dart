import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/themed_background.dart';
import '../../../services/db_service.dart';

/// Fourth step of the booking wizard: select a date.  
///
/// This screen presents a simple calendar with month navigation and a
/// seven‑day preview row. Customers can pick a day for their
/// appointment. The first available day is highlighted with a
/// “Nächst verfügbar” badge. Days that fall on weekends are
/// considered closed and disabled. Selecting a day stores the
/// chosen date in local storage (ISO 8601 string) so that the
/// selection persists. A progress indicator shows the user is on
/// step 4 of 8. After choosing a date the “Weiter” button navigates
/// to the time selection page (step 5).  
/// This implementation is based on the requirements outlined in the
/// specification【522868310347694†L150-L156】.
class BookingSelectDatePage extends StatefulWidget {
  const BookingSelectDatePage({Key? key}) : super(key: key);

  @override
  State<BookingSelectDatePage> createState() => _BookingSelectDatePageState();
}

class _BookingSelectDatePageState extends State<BookingSelectDatePage> {
  late DateTime _displayedMonth;
  DateTime? _selectedDate;
  DateTime? _nextAvailableDate;
  /// Dates on which there is at least one available shift.  Populated
  /// from Supabase via [DbService.getAvailableDates()].  Only these
  /// dates (excluding weekends) are selectable.
  Set<DateTime> _availableDates = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _loadDraftDate();
    // After loading any previously selected date, load available dates
    // for the current month.  We delay this call slightly until
    // widgets have mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableDatesForMonth();
    });
  }

  /// Load the previously selected date from shared preferences, if any.
  Future<void> _loadDraftDate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('draft_date');
    if (stored != null) {
      try {
        final parsed = DateTime.parse(stored);
        setState(() {
          _selectedDate = parsed;
          _displayedMonth = DateTime(parsed.year, parsed.month, 1);
        });
      } catch (_) {
        // ignore invalid format
      }
    }
  }

  /// Select a date and persist it.
  Future<void> _selectDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_date', date.toIso8601String());
    setState(() {
      _selectedDate = date;
    });
  }

  /// Load the available dates for the currently displayed month from
  /// Supabase.  The availability is determined by shifts and filtered
  /// by the selected stylist, if any.  Once loaded, the set of
  /// available dates is stored in [_availableDates] and the earliest
  /// future available date is stored in [_nextAvailableDate].  While
  /// loading, [_isLoading] is true to disable interactions.
  Future<void> _loadAvailableDatesForMonth() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Determine the date range for the current month.
      final monthStart = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
      final monthEnd = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
      // Retrieve the selected stylist id (if any) from shared prefs.
      final prefs = await SharedPreferences.getInstance();
      final stylistStr = prefs.getString('draft_stylist_id');
      int? stylistId;
      if (stylistStr != null && stylistStr.isNotEmpty && stylistStr != '0') {
        stylistId = int.tryParse(stylistStr);
      }
      // Fetch available dates from Supabase.  Ignore errors; they will
      // propagate and can be handled by outer catch.
      final dates = await DbService.getAvailableDates(
        from: monthStart,
        to: monthEnd,
        stylistId: stylistId,
      );
      // Determine the next available date from today onwards.  We
      // ensure the date is on or after today and sort ascending.
      final today = DateTime.now();
      DateTime? next;
      for (final d in dates.toList()..sort()) {
        if (!d.isBefore(DateTime(today.year, today.month, today.day)) && (d.weekday < 6)) {
          next = d;
          break;
        }
      }
      setState(() {
        _availableDates = dates;
        _nextAvailableDate = next;
      });
    } catch (e) {
      // In case of an error we clear available dates to avoid false
      // positives and leave _nextAvailableDate null.
      setState(() {
        _availableDates = {};
        _nextAvailableDate = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Jump to the next available date (if any) by selecting it and
  /// updating the displayed month.  If no next date is known, this
  /// method does nothing.
  void _jumpToNextAvailable() {
    final next = _nextAvailableDate;
    if (next == null) return;
    // If the next date is not in the currently displayed month, update
    // the month to show it.
    if (next.month != _displayedMonth.month || next.year != _displayedMonth.year) {
      setState(() {
        _displayedMonth = DateTime(next.year, next.month, 1);
      });
      // After changing the month, reload available dates for the new
      // month.  Then select the date after the data is loaded.
      _loadAvailableDatesForMonth().then((_) {
        _selectDate(next);
      });
    } else {
      _selectDate(next);
    }
  }

  /// Navigate to the previous month.
  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
    // Reload available dates for the newly displayed month.
    _loadAvailableDatesForMonth();
  }

  /// Navigate to the next month.
  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
    // Reload available dates for the newly displayed month.
    _loadAvailableDatesForMonth();
  }

  /// Build the calendar grid for the displayed month.
  List<Widget> _buildCalendarRows() {
    final List<Widget> rows = [];
    final firstDayOfMonth = _displayedMonth;
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final int startWeekday = firstDayOfMonth.weekday; // 1=Mon .. 7=Sun
    final totalCells = ((startWeekday - 1) + daysInMonth).ceilToDouble() / 7;
    final cellCount = (totalCells.ceil() * 7);
    for (int i = 0; i < cellCount; i++) {
      final int dayNumber = i - (startWeekday - 2);
      DateTime? cellDate;
      if (dayNumber >= 1 && dayNumber <= daysInMonth) {
        cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
      }
      rows.add(_buildDayCell(cellDate));
    }
    // Wrap the cells into rows with 7 columns using Grid
    return rows;
  }

  Widget _buildDayCell(DateTime? date) {
    final today = DateTime.now();
    final bool isDisabled;
    if (date == null) {
      isDisabled = true;
    } else {
      // Disable weekends and dates before today or dates not in the
      // available set.
      final bool isWeekend = date.weekday >= 6;
      final bool beforeToday = date.isBefore(DateTime(today.year, today.month, today.day));
      final bool notAvailable = !_availableDates.contains(date);
      isDisabled = isWeekend || beforeToday || notAvailable;
    }
    final bool isSelected = date != null && _selectedDate != null &&
        date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;
    final bool isNextAvailable = date != null && _nextAvailableDate != null &&
        date.year == _nextAvailableDate!.year &&
        date.month == _nextAvailableDate!.month &&
        date.day == _nextAvailableDate!.day;
    return GestureDetector(
      onTap: isDisabled || date == null
          ? null
          : () {
              _selectDate(date);
            },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              date != null ? '${date.day}' : '',
              style: TextStyle(
                color: isDisabled
                    ? Colors.grey
                    : isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isNextAvailable)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Nächst verfügbar',
                    style: TextStyle(fontSize: 6, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build the seven‑day peek row starting from today.
  Widget _buildSevenDayPeek() {
    final now = DateTime.now();
    final days = List.generate(7, (index) => now.add(Duration(days: index)));
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final bool isSelected = _selectedDate != null &&
              day.year == _selectedDate!.year &&
              day.month == _selectedDate!.month &&
              day.day == _selectedDate!.day;
          final bool isNextAvailable = _nextAvailableDate != null &&
              day.year == _nextAvailableDate!.year &&
              day.month == _nextAvailableDate!.month &&
              day.day == _nextAvailableDate!.day;
          final bool isDisabled = day.weekday >= 6 ||
              day.isBefore(DateTime(now.year, now.month, now.day)) ||
              !_availableDates.contains(DateTime(day.year, day.month, day.day));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat('EEE', 'de_DE').format(day)),
                  Text('${day.day}')
                ],
              ),
              selected: isSelected,
              onSelected: isDisabled
                  ? null
                  : (_) {
                      _selectDate(day);
                    },
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isDisabled
                    ? Colors.grey
                    : isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
              ),
              avatar: isNextAvailable
                  ? const Icon(Icons.star, size: 14)
                  : null,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'de_DE').format(_displayedMonth);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datum auswählen'),
      ),
      body: ThemedBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Step indicator with "Nächst verfügbar" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 4 / 8,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('4/8'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _nextAvailableDate != null ? _jumpToNextAvailable : null,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Nächst verfügbar'),
                ),
              ],
            ),
          ),
          // Month header with navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          // Day of week headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final wd in ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'])
                  Expanded(
                    child: Center(
                      child: Text(
                        wd,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Calendar grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                childAspectRatio: 1.2,
                children: _buildCalendarRows(),
              ),
            ),
          ),
          // Seven‑day peek
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildSevenDayPeek(),
          ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedDate != null
              ? () {
                  Navigator.of(context).pushNamed('/booking/select-time');
                }
              : null,
          child: const Text('Weiter'),
        ),
      ),
    );
  }
}