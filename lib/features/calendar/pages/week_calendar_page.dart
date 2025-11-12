import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonmanager/services/db_service.dart';

/// Represents a booking in the weekly calendar.  Reuses the same structure
/// as in the daily calendar for simplicity.  Each booking has a client
/// name, service description, assigned stylist index, start time and
/// duration (in minutes).
class Booking {
  Booking({
    required this.id,
    required this.client,
    required this.service,
    required this.stylistIndex,
    required this.startTime,
    required this.duration,
  });

  final String id;
  final String client;
  final String service;
  int stylistIndex;
  TimeOfDay startTime;
  int duration;
}

/// Displays a weekly calendar with seven rows (one per day of the current
/// week) and a column for each stylist.  Bookings are shown as simple
/// colour‑coded blocks inside their corresponding day/stylist cell.  A
/// floating action button allows creation of new bookings via a dialog
/// similar to the daily view.
class WeekCalendarPage extends StatefulWidget {
  const WeekCalendarPage({Key? key}) : super(key: key);

  @override
  State<WeekCalendarPage> createState() => _WeekCalendarPageState();
}

class _WeekCalendarPageState extends State<WeekCalendarPage> {
  /// List of stylists loaded from the database. Each map contains id,
  /// name and colour code.  The order of this list determines the
  /// column order in the grid.
  List<Map<String, dynamic>> _stylists = [];

  /// Colours used to represent stylists in the calendar. Populated based on
  /// stylist colour codes from the database or a fallback palette.
  List<Color> stylistColors = [];

  /// Map of bookings keyed by day.  Each entry contains a list of bookings
  /// scheduled on that day.  Bookings know their stylist index and start
  /// time for ordering within the cell.
  Map<DateTime, List<Booking>> bookingsByDay = {};

  /// Indicates whether data is currently being loaded.
  bool _loading = false;

  /// Start date (Monday) of the currently displayed week.  Defaults to
  /// the Monday of the current week on widget initialization.
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    // Compute the start of the current week (Monday).  In Dart, weekday
    // returns values from 1 (Monday) to 7 (Sunday).  Subtracting
    // (weekday - 1) days yields the Monday of the same week.
    final today = DateTime.now();
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
    _loadData();
  }

  /// Loads stylists and bookings for the current week from the database.
  /// For each day in the week (Monday–Sunday) the list of bookings is
  /// retrieved.  Colours are derived from stylist colour codes when
  /// available or fall back to a default palette.
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    try {
      final conn = await DbService.getConnection();
      // Load stylists (id, name, colour)
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
      // Fill up missing colours with a default palette
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
      // Prepare bookings map
      final Map<DateTime, List<Booking>> weekBookings = {};
      // For each day of the week (Monday=0..Sunday=6)
      for (int i = 0; i < 7; i++) {
        final DateTime day = _weekStart.add(Duration(days: i));
        final String dateStr = DateFormat('yyyy-MM-dd').format(day);
        final bookingRows = await conn.query(
          '''
          SELECT b.id,
                 c.first_name AS firstName,
                 c.last_name AS lastName,
                 srv.name AS serviceName,
                 b.stylist_id,
                 b.start_datetime AS startDateTime,
                 b.duration
          FROM bookings b
          JOIN customers c ON b.customer_id = c.id
          JOIN services srv ON b.service_id = srv.id
          WHERE DATE(b.start_datetime) = ? AND b.status IN ('pending','confirmed')
          ORDER BY b.start_datetime
          ''',
          [dateStr],
        );
        final List<Booking> dayBookings = [];
        for (final row in bookingRows) {
          final int stylistId = row['stylist_id'];
          final int stylistIndex = stylists.indexWhere((s) => s['id'] == stylistId);
          // Parse datetime
          DateTime dt;
          final dynamic v = row['startDateTime'];
          if (v is DateTime) {
            dt = v.toLocal();
          } else if (v is String) {
            dt = DateTime.parse(v).toLocal();
          } else {
            dt = DateTime.now();
          }
          final TimeOfDay startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
          final String clientName = '${row['firstName']} ${row['lastName']}';
          dayBookings.add(Booking(
            id: row['id'].toString(),
            client: clientName,
            service: row['serviceName'],
            stylistIndex: stylistIndex < 0 ? 0 : stylistIndex,
            startTime: startTime,
            duration: row['duration'] as int,
          ));
        }
        weekBookings[DateTime(day.year, day.month, day.day)] = dayBookings;
      }
      await conn.close();
      setState(() {
        _stylists = stylists;
        stylistColors = colors;
        bookingsByDay = weekBookings;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Formats a [TimeOfDay] as a human readable HH:MM string.
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Builds a cell for a given [day] and [stylistIndex].  All bookings for
  /// that day and stylist are rendered as small coloured blocks stacked
  /// vertically.  Each block displays the service name and start time.
  Widget _buildCell(DateTime day, int stylistIndex) {
    final dayKey = DateTime(day.year, day.month, day.day);
    final List<Booking> dayBookings = bookingsByDay[dayKey] ?? [];
    // Filter bookings for the current stylist
    final bookingsForStylist =
        dayBookings.where((b) => b.stylistIndex == stylistIndex).toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      width: 120,
      height: 100,
      padding: const EdgeInsets.all(4),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: bookingsForStylist.map((b) {
          final color = stylistColors[stylistIndex % stylistColors.length];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: GestureDetector(
              onTap: () {
                // Show a simple details dialog for now
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Termin: ${b.service}'),
                    content: Text('${b.client}\nBeginn: ${_formatTime(b.startTime)}\nDauer: ${b.duration} min'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Schließen'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                '${b.service}\n${_formatTime(b.startTime)}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Opens a dialog to create a new booking.  The implementation here is
  /// simplified and reuses the same flow as in the daily calendar.  New
  /// bookings are not persisted to the database but will appear in the
  /// current view after submission.  Managers can choose a date within
  /// the current week, stylist, start time, duration and enter client
  /// information.
  Future<void> _createBooking() async {
    final TextEditingController clientController = TextEditingController();
    final TextEditingController serviceController = TextEditingController();
    // Default values
    int selectedStylist = 0;
    DateTime selectedDay = _weekStart;
    TimeOfDay? selectedTime;
    int selectedDuration = 30;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neuen Termin anlegen'),
          content: StatefulBuilder(builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select day
                  DropdownButton<DateTime>(
                    value: selectedDay,
                    items: List.generate(7, (index) {
                      final day = _weekStart.add(Duration(days: index));
                      return DropdownMenuItem(
                        value: day,
                        child: Text(DateFormat('EEE dd.MM.').format(day)),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedDay = v;
                        });
                      }
                    },
                  ),
                  // Select stylist
                  DropdownButton<int>(
                    value: selectedStylist,
                    items: List.generate(_stylists.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(_stylists[index]['name'] ?? 'Stylist'),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedStylist = v;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  // Select start time
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Text(selectedTime == null
                        ? 'Startzeit wählen'
                        : 'Startzeit: ${_formatTime(selectedTime!)}'),
                  ),
                  const SizedBox(height: 8),
                  // Duration
                  DropdownButton<int>(
                    value: selectedDuration,
                    items: const [30, 60, 90, 120]
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d Minuten')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedDuration = v;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: clientController,
                    decoration: const InputDecoration(labelText: 'Kundenname'),
                  ),
                  TextField(
                    controller: serviceController,
                    decoration: const InputDecoration(labelText: 'Leistung'),
                  ),
                ],
              ),
            );
          }),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (selectedTime == null || clientController.text.isEmpty || serviceController.text.isEmpty) {
                  return;
                }
                final newBooking = Booking(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  client: clientController.text,
                  service: serviceController.text,
                  stylistIndex: selectedStylist,
                  startTime: selectedTime!,
                  duration: selectedDuration,
                );
                final dayKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                setState(() {
                  bookingsByDay.putIfAbsent(dayKey, () => []);
                  bookingsByDay[dayKey]!.add(newBooking);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender – Wochenansicht'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    // Header row with empty cell and stylist names
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 40,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 4),
                          child: const Text(''),
                        ),
                        for (int s = 0; s < _stylists.length; s++)
                          Container(
                            width: 120,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              color: stylistColors[s % stylistColors.length].withOpacity(0.1),
                            ),
                            child: Text(
                              _stylists[s]['name'] ?? 'Stylist',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    // Rows per day
                    for (int d = 0; d < 7; d++)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day label
                          Container(
                            width: 80,
                            height: 100,
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              DateFormat('EEE\ndd.MM.').format(_weekStart.add(Duration(days: d))),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          // Cells for each stylist
                          for (int s = 0; s < _stylists.length; s++) _buildCell(_weekStart.add(Duration(days: d)), s),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBooking,
        child: const Icon(Icons.add),
      ),
    );
  }
}