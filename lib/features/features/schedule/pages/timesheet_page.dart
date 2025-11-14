import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Represents a single recorded work time block. Contains start and
/// end timestamps. The net duration (after breaks) is computed when
/// displayed. In a real application the backend would also store the
/// associated stylist and approval status.
class TimeBlock {
  TimeBlock({required this.start, required this.end});
  DateTime start;
  DateTime end;
}

/// Page for recording and viewing working hours. Users can start and
/// stop the timer to create time blocks. Recorded blocks are grouped
/// by day with total hours calculated automatically. Managers can
/// edit or delete entries. This implements Screen 42 of the
/// schedule module.
class TimeSheetPage extends StatefulWidget {
  const TimeSheetPage({Key? key}) : super(key: key);

  @override
  State<TimeSheetPage> createState() => _TimeSheetPageState();
}

class _TimeSheetPageState extends State<TimeSheetPage> {
  /// Whether a time recording is currently active.
  bool _isTracking = false;

  /// Start time of the current active recording.
  DateTime? _currentStart;

  /// Recorded time blocks. Each block has a start and end.
  final List<TimeBlock> _blocks = [];

  /// Calculates the net working hours for a given duration. Applies
  /// simple break rules: 30 minutes deducted for durations over 6
  /// hours, 15 minutes for durations over 4 hours, none otherwise.
  double _calculateNetHours(Duration duration) {
    double hours = duration.inMinutes / 60.0;
    if (hours > 6) {
      hours -= 0.5;
    } else if (hours > 4) {
      hours -= 0.25;
    }
    return hours < 0 ? 0 : hours;
  }

  /// Groups recorded blocks by day (year, month, day) and returns a
  /// map where the key is the date and the value is the list of
  /// blocks. The map keys are sorted descending (latest first).
  Map<DateTime, List<TimeBlock>> _groupBlocksByDay() {
    final Map<DateTime, List<TimeBlock>> grouped = {};
    for (final block in _blocks) {
      final dayKey = DateTime(block.start.year, block.start.month, block.start.day);
      grouped.putIfAbsent(dayKey, () => []).add(block);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final Map<DateTime, List<TimeBlock>> sortedMap = {};
    for (final k in sortedKeys) {
      final list = grouped[k]!;
      list.sort((a, b) => a.start.compareTo(b.start));
      sortedMap[k] = list;
    }
    return sortedMap;
  }

  /// Starts a new time recording.
  void _startTracking() {
    setState(() {
      _isTracking = true;
      _currentStart = DateTime.now();
    });
  }

  /// Stops the current time recording and stores a new block.
  void _stopTracking() {
    if (_currentStart == null) return;
    final end = DateTime.now();
    if (end.isAfter(_currentStart!)) {
      final block = TimeBlock(start: _currentStart!, end: end);
      setState(() {
        _blocks.add(block);
        _isTracking = false;
        _currentStart = null;
      });
    }
  }

  /// Opens a dialog to edit a time block. Allows adjusting start and
  /// end times via time pickers. If the new end is before start, the
  /// change is discarded.
  Future<void> _editBlock(TimeBlock block) async {
    DateTime newStart = block.start;
    DateTime newEnd = block.end;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eintrag bearbeiten'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Start: '),
                      TextButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(newStart),
                          );
                          if (picked != null) {
                            setState(() {
                              newStart = DateTime(
                                newStart.year,
                                newStart.month,
                                newStart.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        child: Text(DateFormat('HH:mm').format(newStart)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Ende: '),
                      TextButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(newEnd),
                          );
                          if (picked != null) {
                            setState(() {
                              newEnd = DateTime(
                                newEnd.year,
                                newEnd.month,
                                newEnd.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        child: Text(DateFormat('HH:mm').format(newEnd)),
                      ),
                    ],
                  ),
                ],
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
                if (newEnd.isAfter(newStart)) {
                  setState(() {
                    block.start = newStart;
                    block.end = newEnd;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a time block from the list.
  void _deleteBlock(TimeBlock block) {
    setState(() {
      _blocks.remove(block);
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupBlocksByDay();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeiterfassung'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isTracking ? null : _startTracking,
                  child: const Text('Arbeitszeit beginnen'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isTracking ? _stopTracking : null,
                  child: const Text('Arbeitszeit beenden'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: grouped.isEmpty
                  ? const Center(child: Text('Noch keine Zeitblöcke erfasst.'))
                  : ListView(
                      children: grouped.entries.map((entry) {
                        final day = entry.key;
                        final blocks = entry.value;
                        double totalHours = 0;
                        for (final b in blocks) {
                          totalHours += _calculateNetHours(b.end.difference(b.start));
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, dd.MM.yyyy', 'de_DE').format(day),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text('Gesamtstunden: ${totalHours.toStringAsFixed(2)}h'),
                                const SizedBox(height: 8),
                                Column(
                                  children: blocks.map((b) {
                                    final duration = b.end.difference(b.start);
                                    final net = _calculateNetHours(duration);
                                    return ListTile(
                                      title: Text(
                                        '${DateFormat('HH:mm').format(b.start)} – ${DateFormat('HH:mm').format(b.end)} (${net.toStringAsFixed(2)}h)',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _editBlock(b),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteBlock(b),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}