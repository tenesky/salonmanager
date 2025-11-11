import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonmanager/services/db_service.dart';

// Reuse the Booking model from the day calendar page to represent
// appointments in the month view. Import with an alias to avoid name
// conflicts when building the day overview.
import 'day_calendar_page.dart' as day;

/// A calendar page showing the month overview. Each day cell displays
/// small coloured dots representing the number of appointments per
/// stylist. Tapping on a day opens a modal with a detailed list of
/// bookings for that date. This implements the Monatsansicht (Screen 38)
/// with mini‑dots and modal day detail as outlined in the Realisierungsplan【73678961014422†L1528-L1532】.
class MonthCalendarPage extends StatefulWidget {
  const MonthCalendarPage({Key? key}) : super(key: key);

  @override
  State<MonthCalendarPage> createState() => _MonthCalendarPageState();
}

class _MonthCalendarPageState extends State<MonthCalendarPage> {
  /// Current month displayed. Changing this will rebuild the grid.
  DateTime _focusedDate = DateTime.now();

  /// Stylists loaded from the database. Each map contains id, name and color.
  List<Map<String, dynamic>> _stylists = [];

  /// Colours derived from stylist colours or default palette.
  List<Color> _stylistColors = [];

  /// A mapping of specific dates to lists of bookings. Each booking
  /// includes start time, duration and assigned stylist index. Bookings
  /// are loaded from the database for the focused month.
  final Map<DateTime, List<day.Booking>> _bookingsByDate = {};

  /// Indicates whether data is currently loading.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads stylists and bookings for the current month from the database.
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    try {
      final conn = await DbService.getConnection();
      // Load stylists and derive colours.
      final stylistRows = await conn.query('SELECT id, name, color FROM stylists ORDER BY id');
      final List<Map<String, dynamic>> stylists = [];
      final List<Color> colors = [];
      for (final row in stylistRows) {
        stylists.add({'id': row['id'], 'name': row['name'], 'color': row['color']});
        final dynamic colorValue = row['color'];
        if (colorValue is String && colorValue.startsWith('#') && colorValue.length == 7) {
          final intColor = int.parse(colorValue.substring(1), radix: 16) + 0xFF000000;
          colors.add(Color(intColor));
        }
      }
      final defaultPalette = [
        Colors.amber.shade700,
        Colors.blue.shade600,
        Colors.green.shade600,
        Colors.purple.shade600,
        Colors.red.shade600,
        Colors.orange.shade600,
      ];
      while (colors.length < stylists.length) {
        colors.add(defaultPalette[colors.length % defaultPalette.length]);
      }
      // Determine first and last date of the month.
      final DateTime firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
      final DateTime lastDay = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
      final String startDateStr = DateFormat('yyyy-MM-dd').format(firstDay);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(lastDay);
      final bookingRows = await conn.query(
        '''
        SELECT b.id,
               b.start_datetime AS startDateTime,
               b.duration,
               b.price,
               b.stylist_id,
               c.first_name AS firstName,
               c.last_name AS lastName,
               srv.name AS serviceName
        FROM bookings b
        JOIN customers c ON b.customer_id = c.id
        JOIN services srv ON b.service_id = srv.id
        WHERE DATE(b.start_datetime) BETWEEN ? AND ?
          AND b.status IN ('pending','confirmed')
        ORDER BY b.start_datetime ASC
        ''',
        [startDateStr, endDateStr],
      );
      final Map<DateTime, List<day.Booking>> grouped = {};
      for (final row in bookingRows) {
        // Determine stylist index by matching ID in stylists list.
        final int stylistId = row['stylist_id'];
        final int stylistIndex = stylists.indexWhere((s) => s['id'] == stylistId);
        // Parse start datetime
        DateTime dt;
        final dynamic v = row['startDateTime'];
        if (v is DateTime) {
          dt = v.toLocal();
        } else if (v is String) {
          dt = DateTime.parse(v).toLocal();
        } else {
          dt = DateTime.now();
        }
        final TimeOfDay timeOfDay = TimeOfDay(hour: dt.hour, minute: dt.minute);
        final dayDate = DateTime(dt.year, dt.month, dt.day);
        final String clientName = '${row['firstName']} ${row['lastName']}';
        final booking = day.Booking(
          id: row['id'].toString(),
          client: clientName,
          service: row['serviceName'],
          stylistIndex: stylistIndex < 0 ? 0 : stylistIndex,
          startTime: timeOfDay,
          duration: row['duration'] as int,
        );
        grouped.putIfAbsent(dayDate, () => []).add(booking);
      }
      await conn.close();
      setState(() {
        _stylists = stylists;
        _stylistColors = colors;
        _bookingsByDate
          ..clear()
          ..addAll(grouped);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Returns the number of bookings for a given date and stylist index.
  int _countBookingsForStylist(DateTime date, int stylistIndex) {
    final bookings = _bookingsByDate[date];
    if (bookings == null) return 0;
    return bookings.where((b) => b.stylistIndex == stylistIndex).length;
  }

  /// Move to the previous month and reload data from the database.
  void _goToPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    });
    _loadData();
  }

  /// Move to the next month and reload data from the database.
  void _goToNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDate.year, _focusedDate.month);
    final int startWeekday = firstOfMonth.weekday; // Monday=1, Sunday=7
    final int leadingEmptyCells = startWeekday - 1;
    final int totalCells = ((leadingEmptyCells + daysInMonth) / 7).ceil() * 7;
    final List<String> weekdayLabels = const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_monthName(_focusedDate.month)} ${_focusedDate.year}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPreviousMonth,
            tooltip: 'Vorheriger Monat',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextMonth,
            tooltip: 'Nächster Monat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Weekday header
          Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  child: Text(
                    weekdayLabels[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              );
            }),
          ),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < leadingEmptyCells || index >= leadingEmptyCells + daysInMonth) {
                  return Container();
                }
                final dayNumber = index - leadingEmptyCells + 1;
                final date = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
                return GestureDetector(
                  onTap: () => _openDayModal(date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        _buildMiniDots(date),
                      ],
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

  /// Build a row of coloured dots indicating the number of bookings per
  /// stylist on the given date. If there are no bookings, returns an
  /// empty container to save space. Each stylist gets as many dots as
  /// they have bookings (up to a reasonable limit). The colours come
  /// from [stylistColors].
  Widget _buildMiniDots(DateTime date) {
    final bookings = _bookingsByDate[date];
    if (bookings == null || bookings.isEmpty) {
      return const SizedBox.shrink();
    }
    // Count bookings per stylist.
    final counts = List<int>.generate(_stylists.length, (_) => 0);
    for (final b in bookings) {
      if (b.stylistIndex >= 0 && b.stylistIndex < counts.length) {
        counts[b.stylistIndex]++;
      }
    }
    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: counts.asMap().entries.expand((entry) {
        final index = entry.key;
        final count = entry.value;
        return List.generate(count, (_) {
          return Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 2, bottom: 2),
            decoration: BoxDecoration(
              color: _stylistColors[index % _stylistColors.length],
              shape: BoxShape.circle,
            ),
          );
        });
      }).toList(),
    );
  }

  /// Open a modal bottom sheet showing all bookings for the selected date.
  void _openDayModal(DateTime date) {
    final List<day.Booking> bookings = _bookingsByDate[date] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DayOverviewSheet(
          date: date,
          bookings: bookings,
          stylists: _stylists.map((s) => s['name']?.toString() ?? '').toList(),
          stylistColors: _stylistColors,
        );
      },
    );
  }

  /// Convert a month number to its German month name. This could be
  /// replaced with localisation (l10n) support in a real application.
  String _monthName(int month) {
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ];
    return months[(month - 1) % 12];
  }
}

/// A modal sheet displaying a list of appointments for a specific date.
/// Shows each booking’s time, service, client and assigned stylist with
/// colour coding. If there are no bookings, displays a friendly empty
/// state.
class DayOverviewSheet extends StatelessWidget {
  const DayOverviewSheet({
    Key? key,
    required this.date,
    required this.bookings,
    required this.stylists,
    required this.stylistColors,
  }) : super(key: key);

  final DateTime date;
  final List<day.Booking> bookings;
  final List<String> stylists;
  final List<Color> stylistColors;

  /// Helper to format a TimeOfDay.
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Compute end time given a start and duration.
  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final total = time.hour * 60 + time.minute + minutes;
    final hour = (total ~/ 60) % 24;
    final minute = total % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.';
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Termine am $dateLabel',
                  // Use titleMedium instead of deprecated subtitle1.
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (bookings.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Keine Termine an diesem Tag',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final color = stylistColors[booking.stylistIndex % stylistColors.length];
                    final stylistName = stylists[booking.stylistIndex];
                    final start = _formatTime(booking.startTime);
                    final end = _formatTime(_addMinutes(booking.startTime, booking.duration));
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        radius: 6,
                      ),
                      title: Text('${booking.service}  ($start–$end)'),
                      subtitle: Text('${booking.client}  –  $stylistName'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}