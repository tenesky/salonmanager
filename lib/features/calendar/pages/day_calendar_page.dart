import 'package:flutter/material.dart';
import 'package:salonmanager/services/db_service.dart';

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

  /// Selected date for which bookings are displayed. Defaults to today.
  DateTime _selectedDate = DateTime.now();

  /// Stylists loaded from the database. Each map contains id, name and color.
  List<Map<String, dynamic>> _stylists = [];

  /// Services loaded from the database. Each map contains id, name, price and duration.
  List<Map<String, dynamic>> _services = [];

  /// Colours used to represent stylists in the calendar. Populated based on
  /// stylist colour codes from the database or fallback palette.
  List<Color> stylistColors = [];

  /// Keys to determine the position of each column for drag calculations.
  List<GlobalKey> columnKeys = [];

  /// List of bookings displayed in the calendar. Each booking knows its
  /// stylist index, start time and duration.
  List<Booking> bookings = [];

  /// Indicates whether data is currently being loaded.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads stylists, services and bookings for the selected date from the
  /// database. This method populates the internal lists and colours
  /// accordingly. Colours are derived from stylist colour codes when
  /// available (hex strings), otherwise a default palette is used.
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    try {
      // Load stylists and derive their colours.  Colours are parsed from
      // the hex strings stored in the database; when a stylist has no
      // colour specified, a default palette entry is used.
      final List<Map<String, dynamic>> stylists = await DbService.getStylists();
      final List<Color> colors = [];
      for (final stylist in stylists) {
        final dynamic colorValue = stylist['color'];
        if (colorValue is String && colorValue.startsWith('#') && colorValue.length == 7) {
          final intColor = int.parse(colorValue.substring(1), radix: 16) + 0xFF000000;
          colors.add(Color(intColor));
        }
      }
      // Fill remaining colours with defaults if necessary
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
      // Load services
      final List<Map<String, dynamic>> services = await DbService.getServices();
      // Load bookings for the selected date with details
      final List<Map<String, dynamic>> bookingRows =
          await DbService.getDetailedBookingsForDate(_selectedDate);
      final List<Booking> loadedBookings = [];
      for (final row in bookingRows) {
        // Determine stylist index by matching stylist_id in stylists list
        final int stylistId = row['stylist_id'] as int;
        final int stylistIndex = stylists.indexWhere((s) => s['id'] == stylistId);
        // Parse start datetime (UTC or local) into TimeOfDay
        DateTime dt;
        final dynamic v = row['start_datetime'];
        if (v is DateTime) {
          dt = v.toLocal();
        } else if (v is String) {
          dt = DateTime.parse(v).toLocal();
        } else {
          dt = DateTime.now();
        }
        final TimeOfDay startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        final String firstName = row['firstName']?.toString() ?? '';
        final String lastName = row['lastName']?.toString() ?? '';
        final String clientName = (firstName + ' ' + lastName).trim();
        loadedBookings.add(Booking(
          id: row['id'].toString(),
          client: clientName,
          service: row['serviceName']?.toString() ?? '',
          stylistIndex: stylistIndex < 0 ? 0 : stylistIndex,
          startTime: startTime,
          duration: row['duration'] as int,
        ));
      }
      setState(() {
        _stylists = stylists;
        stylistColors = colors;
        columnKeys = List.generate(stylists.length, (_) => GlobalKey());
        _services = services;
        bookings = loadedBookings;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
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
    int selectedStylist = 0;
    int selectedServiceIndex = 0;
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
                        _stylists.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(_stylists[index]['name']?.toString() ?? ''),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Service selection
                    DropdownButton<int>(
                      value: selectedServiceIndex,
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedServiceIndex = value;
                          });
                        }
                      },
                      items: List.generate(
                        _services.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(_services[index]['name']?.toString() ?? ''),
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
                        DropdownMenuItem(value: 45, child: Text('45 Min')),
                        DropdownMenuItem(value: 60, child: Text('60 Min')),
                        DropdownMenuItem(value: 90, child: Text('90 Min')),
                        DropdownMenuItem(value: 120, child: Text('120 Min')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Client name
                    TextField(
                      controller: clientController,
                      decoration: const InputDecoration(
                        labelText: 'Kunde (Vor- und Nachname)',
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
            ElevatedButton(
              onPressed: () async {
                if (selectedTime != null && clientController.text.isNotEmpty) {
                  // Parse client name (first and last name separated by space)
                  final names = clientController.text.trim().split(' ');
                  final String firstName = names.isNotEmpty ? names.first : '';
                  final String lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
                  try {
                    // Resolve ids and details for stylist and service
                    final int stylistId = _stylists[selectedStylist]['id'] as int;
                    final Map<String, dynamic> service = _services[selectedServiceIndex];
                    final int serviceId = service['id'] as int;
                    final double price = (service['price'] as num).toDouble();
                    final int duration = selectedDuration;
                    // Construct the local start datetime for the appointment
                    final DateTime startDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                    // Create the customer and booking via Supabase helpers
                    final int customerId = await DbService.createCustomer(
                      firstName: firstName,
                      lastName: lastName,
                    );
                    await DbService.createBooking(
                      customerId: customerId,
                      stylistId: stylistId,
                      serviceId: serviceId,
                      startDateTime: startDateTime,
                      duration: duration,
                      price: price,
                      status: 'pending',
                    );
                    Navigator.of(context).pop();
                    // Reload data to reflect new booking
                    _loadData();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Termin erstellt.')),
                    );
                  } catch (_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Fehler beim Erstellen des Termins.')),
                    );
                  }
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
                      // Use bodySmall instead of deprecated caption.
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }),
              ],
            ),
            // Columns for each stylist
            ...List.generate(_stylists.length, (stylistIndex) {
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
            _stylists[stylistIndex]['name']?.toString() ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // Drag target for bookings
        DragTarget<Booking>(
          onWillAccept: (data) => true,
          onAcceptWithDetails: (DragTargetDetails<Booking> details) async {
            // Translate global drop offset to local position within this column.
            final renderBox = columnKeys[stylistIndex]
                .currentContext
                ?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final local = renderBox.globalToLocal(details.offset);
              // Subtract the header height to align with the timeline.
              final double y = local.dy - slotHeight;
              // Compute the index of the time slot based on vertical position.
              int slotIndex = (y / slotHeight).floor().clamp(0, slotCount - 1);
              // Derive new start time.
              final int startMinutes =
                  (startOfDay.hour * 60 + startOfDay.minute) + slotIndex * 30;
              final int newHour = startMinutes ~/ 60;
              final int newMinute = startMinutes % 60;
              setState(() {
                final booking = details.data;
                booking.stylistIndex = stylistIndex;
                booking.startTime = TimeOfDay(hour: newHour, minute: newMinute);
              });
              // Persist the updated position to Supabase.  Errors are
              // caught and ignored to avoid disrupting the drag UI.
              try {
                final booking = details.data;
                final int bookingId = int.tryParse(booking.id) ?? 0;
                final int stylistId = _stylists[stylistIndex]['id'] as int;
                final DateTime newStartDateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  newHour,
                  newMinute,
                );
                await DbService.updateBookingStartAndStylist(
                  bookingId: bookingId,
                  stylistId: stylistId,
                  startDateTime: newStartDateTime,
                );
              } catch (_) {
                // ignore database errors in drag
              }
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            booking.client,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
          ),
          Text(
            '${_formatTime(booking.startTime)}  -  ${_formatTime(_addMinutes(booking.startTime, booking.duration))}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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