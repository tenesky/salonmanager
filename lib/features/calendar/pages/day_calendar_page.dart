import 'package:flutter/material.dart';

/// Represents a booking in the daily calendar.
///
/// Contains client and service info, assigned stylist index, start time,
/// duration (in minutes) and a unique id for drag & drop.
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

/// Displays a horizontal timeline per day with a column for each stylist.
///
/// This page implements the daily calendar (Screen 36) as described in the
/// Realisierungsplan: a timeline with columns per employee, drag‑&‑drop
/// to reschedule bookings and a floating action button to quickly create
/// new appointments【73678961014422†L1528-L1532】.
class DayCalendarPage extends StatefulWidget {
  const DayCalendarPage({Key? key}) : super(key: key);

  @override
  State<DayCalendarPage> createState() => _DayCalendarPageState();
}

class _DayCalendarPageState extends State<DayCalendarPage> {
  /// Define a fixed working day (8 – 20 Uhr) in 30 Minute‑Schritten.
  final TimeOfDay startOfDay = const TimeOfDay(hour: 8, minute: 0);
  final int slotCount = 24; // 12 hours × 2 = 24 slots of 30 minutes
  final double slotHeight = 60.0;

  // Sample stylists. In a real app these would be loaded from the backend.
  final List<String> stylists = ['Anna', 'Ben', 'Caro'];

  // Unique colour per stylist. Colours are drawn from the theme’s palette to
  // emphasise different staff members without hardcoding specific hues.
  late final List<Color> stylistColors;

  // Keys to determine the position of each column for drag calculations.
  late final List<GlobalKey> columnKeys;

  // List of bookings displayed in the calendar. Each booking knows its
  // stylist index, start time and duration.
  late List<Booking> bookings;

  @override
  void initState() {
    super.initState();
    // Initialize stylist colours using the theme’s colorScheme. We cycle
    // through primary and secondary with different opacity to distinguish
    // stylists.
    stylistColors = [
      Colors.amber.shade700,
      Colors.blue.shade600,
      Colors.green.shade600,
    ];
    // Create global keys for each column so we can translate global drop
    // coordinates to local offsets when a booking is dropped.
    columnKeys = List.generate(stylists.length, (_) => GlobalKey());
    // Sample bookings for demonstration. In production these would come
    // from the backend and be filtered by the selected day.
    bookings = [
      Booking(
        id: '1',
        client: 'Kunde A',
        service: 'Haarschnitt',
        stylistIndex: 0,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        duration: 60,
      ),
      Booking(
        id: '2',
        client: 'Kunde B',
        service: 'Farbe',
        stylistIndex: 1,
        startTime: const TimeOfDay(hour: 10, minute: 30),
        duration: 90,
      ),
      Booking(
        id: '3',
        client: 'Kunde C',
        service: 'Bartpflege',
        stylistIndex: 2,
        startTime: const TimeOfDay(hour: 13, minute: 0),
        duration: 30,
      ),
    ];
  }

  /// Helper to format TimeOfDay to a readable string.
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Open a dialog for creating a new booking. The user can select a
  /// stylist, start time, duration and enter the client and service name.
  Future<void> _createBooking() async {
    final TextEditingController clientController = TextEditingController();
    final TextEditingController serviceController = TextEditingController();
    int selectedStylist = 0;
    TimeOfDay? selectedTime;
    int selectedDuration = 30;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neuen Termin erstellen'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stylist selection
                    DropdownButton<int>(
                      value: selectedStylist,
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedStylist = value;
                          });
                        }
                      },
                      items: List.generate(
                        stylists.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(stylists[index]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time picker
                    Row(
                      children: [
                        const Text('Uhrzeit:'),
                        const SizedBox(width: 8),
                        Text(
                          selectedTime != null ? _formatTime(selectedTime!) : '–',
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedTime = picked;
                              });
                            }
                          },
                          child: const Text('Auswählen'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Duration picker
                    DropdownButton<int>(
                      value: selectedDuration,
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedDuration = value;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 Min')),
                        DropdownMenuItem(value: 60, child: Text('60 Min')),
                        DropdownMenuItem(value: 90, child: Text('90 Min')),
                        DropdownMenuItem(value: 120, child: Text('120 Min')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: clientController,
                      decoration: const InputDecoration(
                        labelText: 'Kunde',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: serviceController,
                      decoration: const InputDecoration(
                        labelText: 'Leistung',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (selectedTime != null &&
                    clientController.text.isNotEmpty &&
                    serviceController.text.isNotEmpty) {
                  setState(() {
                    bookings.add(
                      Booking(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        client: clientController.text,
                        service: serviceController.text,
                        stylistIndex: selectedStylist,
                        startTime: selectedTime!,
                        duration: selectedDuration,
                      ),
                    );
                  });
                  Navigator.of(context).pop();
                }
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
    // Generate time slots for the day.
    final List<TimeOfDay> timeSlots = List.generate(slotCount, (index) {
      final totalMinutes =
          (startOfDay.hour * 60 + startOfDay.minute) + (index * 30);
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      return TimeOfDay(hour: hour, minute: minute);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagesansicht'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBooking,
        tooltip: 'Neuer Termin',
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time labels column
            Column(
              children: [
                // Top-left empty cell
                Container(
                  height: slotHeight,
                  width: 80,
                  color: Colors.transparent,
                ),
                ...List.generate(timeSlots.length, (index) {
                  return Container(
                    height: slotHeight,
                    width: 80,
                    padding: const EdgeInsets.only(right: 4),
                    alignment: Alignment.topRight,
                    child: Text(
                      _formatTime(timeSlots[index]),
                      style: Theme.of(context).textTheme.caption,
                    ),
                  );
                }),
              ],
            ),
            // Columns for each stylist
            ...List.generate(stylists.length, (stylistIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _buildStylistColumn(stylistIndex),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds a single column for a stylist. Includes a header with the stylist
  /// name and a scrollable timeline area with bookings as draggable cards.
  Widget _buildStylistColumn(int stylistIndex) {
    return Column(
      key: columnKeys[stylistIndex],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: slotHeight,
          width: 180,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Text(
            stylists[stylistIndex],
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ),
        // Drag target for bookings
        DragTarget<Booking>(
          onWillAccept: (data) => true,
          onAcceptWithDetails: (DragTargetDetails<Booking> details) {
            // Translate global drop offset to local position within this column.
            final renderBox = columnKeys[stylistIndex]
                .currentContext
                ?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final local = renderBox.globalToLocal(details.offset);
              // Subtract the header height to align with the timeline.
              final y = local.dy - slotHeight;
              // Compute the index of the time slot based on vertical position.
              int slotIndex = (y / slotHeight).floor().clamp(0, slotCount - 1);
              // Derive new start time.
              final startMinutes =
                  (startOfDay.hour * 60 + startOfDay.minute) + slotIndex * 30;
              final newHour = startMinutes ~/ 60;
              final newMinute = startMinutes % 60;
              setState(() {
                final booking = details.data;
                booking.stylistIndex = stylistIndex;
                booking.startTime = TimeOfDay(hour: newHour, minute: newMinute);
              });
            }
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              width: 180,
              height: slotHeight * slotCount,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Stack(
                children: bookings
                    .where((b) => b.stylistIndex == stylistIndex)
                    .map((b) {
                  final startMinutes = b.startTime.hour * 60 + b.startTime.minute;
                  final dayStartMinutes =
                      startOfDay.hour * 60 + startOfDay.minute;
                  final diffMinutes = startMinutes - dayStartMinutes;
                  final topOffset = (diffMinutes / 30) * slotHeight;
                  final height = (b.duration / 30) * slotHeight;
                  return Positioned(
                    left: 4,
                    right: 4,
                    top: topOffset,
                    height: height,
                    child: _buildBookingCard(b),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build the visual representation of a booking. This widget is wrapped in
  /// [LongPressDraggable] to allow repositioning by dragging. The card
  /// displays the service, client and time. When being dragged, a slightly
  /// translucent feedback is shown.
  Widget _buildBookingCard(Booking booking) {
    final color =
        stylistColors[booking.stylistIndex % stylistColors.length];
    return LongPressDraggable<Booking>(
      data: booking,
      feedback: Material(
        elevation: 4,
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: _bookingContent(booking, color),
        ),
      ),
      childWhenDragging: Container(),
      child: _bookingContent(booking, color),
    );
  }

  /// Content builder for a booking card.
  Widget _bookingContent(Booking booking, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.service,
            style: Theme.of(context).textTheme.bodyText2?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            booking.client,
            style: Theme.of(context).textTheme.caption?.copyWith(
                  color: Colors.white,
                ),
          ),
          Text(
            '${_formatTime(booking.startTime)}  -  ${_formatTime(_addMinutes(booking.startTime, booking.duration))}',
            style: Theme.of(context).textTheme.overline?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  /// Helper to add minutes to a TimeOfDay. Used to display end times.
  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }
}