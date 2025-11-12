import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonmanager/services/db_service.dart';

/// Represents a shift on the schedule board. Each shift has an id, the
/// index of the stylist it belongs to, the index of the day (0 = Monday,
/// 6 = Sunday), a start time and duration. Duration is stored in
/// minutes.
class Shift {
  Shift({
    required this.id,
    required this.stylistIndex,
    required this.dayIndex,
    required this.startTime,
    required this.duration,
  });
  final String id;
  int stylistIndex;
  int dayIndex;
  TimeOfDay startTime;
  int duration;
}

/// Displays a drag‑and‑drop schedule board.  Stylists are shown as rows
/// and each day of the week as columns.  Shifts appear as coloured
/// blocks within their respective cell.  Managers can create new
/// shifts, move them to other days or stylists via drag‑and‑drop, and
/// duplicate or delete them using a context menu.
class ScheduleBoardPage extends StatefulWidget {
  const ScheduleBoardPage({Key? key}) : super(key: key);

  @override
  State<ScheduleBoardPage> createState() => _ScheduleBoardPageState();
}

class _ScheduleBoardPageState extends State<ScheduleBoardPage> {
  /// List of stylists loaded from the database. Each entry contains id,
  /// name and an optional colour string.
  List<Map<String, dynamic>> _stylists = [];

  /// Colours assigned to stylists.  Will be derived from database
  /// values or fall back to a default palette.
  List<Color> stylistColors = [];

  /// List of all shifts currently displayed on the board.
  List<Shift> shifts = [];

  /// Indicates whether the board is currently loading data.
  bool _loading = false;

  /// Start of the current week (Monday). Used to label the columns.
  late DateTime _weekStart;

  /// Defines the beginning of the day for shift calculations (8 Uhr).
  final TimeOfDay startOfDay = const TimeOfDay(hour: 8, minute: 0);

  /// Total minutes represented in a day (12 Stunden).  Used to compute
  /// vertical scaling of shift blocks.
  final int totalMinutes = 12 * 60; // 12 hours from 08:00 to 20:00

  /// Height of each cell in the grid (in pixels).
  final double cellHeight = 480.0;

  /// Width of each day column (in pixels).
  final double cellWidth = 150.0;

  @override
  void initState() {
    super.initState();
    // Determine start of week (Monday)
    final DateTime today = DateTime.now();
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
    _loadStylists();
  }

  /// Loads stylists from the database and initialises colours.  After
  /// loading, a few example shifts are generated for demonstration
  /// purposes.  In a real implementation shifts would be loaded from
  /// the backend instead of being hard coded.
  Future<void> _loadStylists() async {
    setState(() {
      _loading = true;
    });
    try {
      final List<Map<String, dynamic>> stylists = await DbService.getStylists();
      final List<Color> colours = [];
      for (final row in stylists) {
        final dynamic colorValue = row['color'];
        if (colorValue is String && colorValue.startsWith('#') && colorValue.length == 7) {
          final intColor = int.parse(colorValue.substring(1), radix: 16) + 0xFF000000;
          colours.add(Color(intColor));
        }
      }
      // Fill missing colours with defaults
      final defaultPalette = [
        Colors.amber.shade700,
        Colors.blue.shade600,
        Colors.green.shade600,
        Colors.purple.shade600,
        Colors.red.shade600,
        Colors.orange.shade600,
      ];
      while (colours.length < stylists.length) {
        colours.add(defaultPalette[colours.length % defaultPalette.length]);
      }
      setState(() {
        _stylists = stylists;
        stylistColors = colours;
        // Generate a few example shifts spanning different days and stylists
        shifts = [];
        if (stylists.isNotEmpty) {
          for (int i = 0; i < stylists.length; i++) {
            shifts.add(Shift(
              id: 's${i}_1',
              stylistIndex: i,
              dayIndex: 0,
              startTime: const TimeOfDay(hour: 9, minute: 0),
              duration: 240,
            ));
            shifts.add(Shift(
              id: 's${i}_2',
              stylistIndex: i,
              dayIndex: 2,
              startTime: const TimeOfDay(hour: 13, minute: 0),
              duration: 180,
            ));
          }
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Calculates the vertical offset of a shift within a cell based on its
  /// start time relative to [_startOfDay].  Returns a value in pixels.
  double _calculateTopOffset(TimeOfDay time) {
    final int minutesFromStart = (time.hour - startOfDay.hour) * 60 + (time.minute - startOfDay.minute);
    final double relative = minutesFromStart / totalMinutes;
    return relative.clamp(0.0, 1.0) * cellHeight;
  }

  /// Calculates the height of a shift block based on its duration.
  double _calculateBlockHeight(int duration) {
    final double relative = duration / totalMinutes;
    return (relative * cellHeight).clamp(30.0, cellHeight);
  }

  /// Opens a dialog to create a new shift.  The user can select a stylist,
  /// a day of the week, start time and duration.  The created shift is
  /// added to the board but not persisted.  Duplicate ids are avoided
  /// by generating a timestamp string.
  Future<void> _createShift() async {
    if (_stylists.isEmpty) return;
    // Default values
    int selectedStylist = 0;
    int selectedDayIndex = 0;
    TimeOfDay? selectedTime;
    int selectedDuration = 240;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neue Schicht anlegen'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stylist selection
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
                    // Day selection
                    DropdownButton<int>(
                      value: selectedDayIndex,
                      items: List.generate(7, (index) {
                        final DateTime day = _weekStart.add(Duration(days: index));
                        return DropdownMenuItem(
                          value: index,
                          child: Text(DateFormat('EEE dd.MM.').format(day)),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            selectedDayIndex = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    // Start time selection
                    ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      child: Text(selectedTime == null
                          ? 'Startzeit wählen'
                          : 'Startzeit: ${selectedTime!.format(context)}'),
                    ),
                    const SizedBox(height: 8),
                    // Duration selection
                    DropdownButton<int>(
                      value: selectedDuration,
                      items: const [120, 180, 240, 300, 360]
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('${d ~/ 60} Std'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            selectedDuration = v;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (selectedTime == null) return;
                final newShift = Shift(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  stylistIndex: selectedStylist,
                  dayIndex: selectedDayIndex,
                  startTime: selectedTime!,
                  duration: selectedDuration,
                );
                setState(() {
                  shifts.add(newShift);
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

  /// Duplicates a shift and places the copy on the same day and stylist
  /// immediately after the original shift.  The new shift receives a
  /// unique id and its start time is offset by its duration.
  void _duplicateShift(Shift original) {
    final TimeOfDay newStart = TimeOfDay(
      hour: original.startTime.hour + (original.startTime.minute + original.duration) ~/ 60,
      minute: (original.startTime.minute + original.duration) % 60,
    );
    final newShift = Shift(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      stylistIndex: original.stylistIndex,
      dayIndex: original.dayIndex,
      startTime: newStart,
      duration: original.duration,
    );
    setState(() {
      shifts.add(newShift);
    });
  }

  /// Deletes a shift from the board.
  void _deleteShift(Shift shift) {
    setState(() {
      shifts.removeWhere((s) => s.id == shift.id);
    });
  }

  /// Returns true if two shifts overlap (same stylist and day) and their
  /// times intersect.  Used to display conflict indicators.
  bool _isConflict(Shift a, Shift b) {
    if (a.stylistIndex != b.stylistIndex || a.dayIndex != b.dayIndex) return false;
    final int aStart = a.startTime.hour * 60 + a.startTime.minute;
    final int aEnd = aStart + a.duration;
    final int bStart = b.startTime.hour * 60 + b.startTime.minute;
    final int bEnd = bStart + b.duration;
    return (aStart < bEnd) && (bStart < aEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schichtplan'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stylists.isEmpty
              ? const Center(child: Text('Keine Stylisten gefunden'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        // Header row: empty corner then day labels
                        Row(
                          children: [
                            Container(
                              width: 100,
                              height: 40,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 4),
                              child: const Text(''),
                            ),
                            for (int day = 0; day < 7; day++)
                              Container(
                                width: cellWidth,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  color: Colors.grey.shade200,
                                ),
                                child: Text(DateFormat('EEE dd.MM.').format(_weekStart.add(Duration(days: day)))),
                              ),
                          ],
                        ),
                        // Row per stylist
                        for (int s = 0; s < _stylists.length; s++)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stylist name label
                              Container(
                                width: 100,
                                height: cellHeight,
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  color: stylistColors[s % stylistColors.length].withOpacity(0.1),
                                ),
                                child: Text(
                                  _stylists[s]['name'] ?? 'Stylist',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Cells for each day
                              for (int day = 0; day < 7; day++)
                                DragTarget<Shift>(
                                  onWillAccept: (shift) {
                                    // Always allow drop
                                    return true;
                                  },
                                  onAccept: (shift) {
                                    setState(() {
                                      shift.stylistIndex = s;
                                      shift.dayIndex = day;
                                    });
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    // Build cell content: stack of shifts for this stylist and day
                                    final cellShifts = shifts.where((sh) => sh.stylistIndex == s && sh.dayIndex == day).toList();
                                    return Container(
                                      width: cellWidth,
                                      height: cellHeight,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Shifts
                                          for (final sh in cellShifts) ...[
                                            Positioned(
                                              top: _calculateTopOffset(sh.startTime),
                                              left: 4,
                                              right: 4,
                                              height: _calculateBlockHeight(sh.duration),
                                              child: Draggable<Shift>(
                                                data: sh,
                                                feedback: _buildShiftBlock(sh, s, isFeedback: true),
                                                childWhenDragging: Container(),
                                                onDragEnd: (details) {
                                                  // No action here; updates happen in onAccept of DragTarget
                                                },
                                                child: _buildShiftBlock(sh, s),
                                              ),
                                            ),
                                          ],
                                          // Optional indicator for drop target highlight
                                          if (candidateData.isNotEmpty)
                                            Positioned.fill(
                                              child: Container(
                                                color: Colors.blue.withOpacity(0.1),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createShift,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Builds the visual representation of a shift.  Includes a context
  /// menu on long press for duplicating or deleting the shift.  If
  /// conflicts exist with other shifts, a warning icon is shown.
  Widget _buildShiftBlock(Shift shift, int stylistIndex, {bool isFeedback = false}) {
    final Color baseColor = stylistColors[stylistIndex % stylistColors.length];
    // Determine if this shift conflicts with any other shift
    final bool hasConflict = shifts.any((other) => other != shift && _isConflict(shift, other));
    final block = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(isFeedback ? 0.5 : 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '${shift.startTime.format(context)}\n${(shift.duration / 60).toStringAsFixed(1)}h',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
          if (hasConflict)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.warning, color: Colors.red.shade200, size: 16),
            ),
        ],
      ),
    );
    if (isFeedback) {
      return Material(
        color: Colors.transparent,
        child: block,
      );
    }
    return GestureDetector(
      onLongPress: () async {
        final selected = await showMenu<String>(
          context: context,
          position: const RelativeRect.fromLTRB(100, 100, 0, 0),
          items: [
            const PopupMenuItem(value: 'duplicate', child: Text('Duplizieren')),
            const PopupMenuItem(value: 'delete', child: Text('Löschen')),
          ],
        );
        if (selected == 'duplicate') {
          _duplicateShift(shift);
        } else if (selected == 'delete') {
          _deleteShift(shift);
        }
      },
      child: block,
    );
  }
}