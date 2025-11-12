import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonmanager/services/db_service.dart';

/// Represents a basic shift used for the swap page. It has a stylist
/// index, day index and start/end times. The id is only used
/// internally for identifying swaps.
class SimpleShift {
  SimpleShift({
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

/// Represents a shift swap request. A stylist can request to swap a
/// shift with another stylist. Managers can accept or decline the
/// request. Only the id and status are persisted; everything else is
/// derived for display purposes.
class SwapRequest {
  SwapRequest({
    required this.id,
    required this.shift,
    required this.toStylistIndex,
    required this.message,
    this.status = SwapStatus.pending,
  });
  final String id;
  final SimpleShift shift;
  final int toStylistIndex;
  final String message;
  SwapStatus status;
}

/// Status of a swap request.
enum SwapStatus { pending, accepted, declined }

/// Screen for viewing and managing shift swap requests. Stylists see a
/// list of their upcoming shifts with a button to request a swap. A
/// dialog allows selecting a colleague and entering a message. Managers
/// can review all pending requests and accept or decline them. This
/// implements Screen 40 of the schedule module.
class ShiftSwapPage extends StatefulWidget {
  const ShiftSwapPage({Key? key}) : super(key: key);

  @override
  State<ShiftSwapPage> createState() => _ShiftSwapPageState();
}

class _ShiftSwapPageState extends State<ShiftSwapPage> {
  /// List of stylists loaded from the database. Each entry contains id,
  /// name and an optional colour string.
  List<Map<String, dynamic>> _stylists = [];

  /// List of shifts assigned to the current user. For demonstration
  /// purposes, we generate some sample shifts. In a real app the
  /// backend would provide actual assignments.
  List<SimpleShift> _myShifts = [];

  /// List of swap requests. When a stylist requests a swap, a new entry
  /// is added here. Managers review and update the status of each
  /// request.
  final List<SwapRequest> _requests = [];

  /// Flag to indicate whether the page is currently loading data.
  bool _loading = false;

  /// Start of the current week (Monday) used to label days.
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final DateTime today = DateTime.now();
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
    _loadStylistsAndShifts();
  }

  /// Loads stylists from the database and generates example shifts for
  /// demonstration. In production, the backend would supply the
  /// stylist assignments and swap requests.
  Future<void> _loadStylistsAndShifts() async {
    setState(() {
      _loading = true;
    });
    try {
      final conn = await DbService.getConnection();
      final rows = await conn.query('SELECT id, name FROM stylists ORDER BY id');
      final List<Map<String, dynamic>> stylists = [];
      for (final row in rows) {
        stylists.add({'id': row['id'], 'name': row['name']});
      }
      await conn.close();
      // Generate sample shifts: assign the first two stylists a couple of
      // shifts this week. In a real implementation you would fetch
      // actual shifts for the logged in user.
      final List<SimpleShift> myShifts = [];
      if (stylists.isNotEmpty) {
        // Example: the first stylist has shifts on Monday and Thursday
        myShifts.add(SimpleShift(
          id: 'sh1',
          stylistIndex: 0,
          dayIndex: 0,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          duration: 240,
        ));
        myShifts.add(SimpleShift(
          id: 'sh2',
          stylistIndex: 0,
          dayIndex: 3,
          startTime: const TimeOfDay(hour: 14, minute: 0),
          duration: 180,
        ));
        if (stylists.length > 1) {
          // Another shift on Friday for demonstration
          myShifts.add(SimpleShift(
            id: 'sh3',
            stylistIndex: 0,
            dayIndex: 4,
            startTime: const TimeOfDay(hour: 10, minute: 0),
            duration: 180,
          ));
        }
      }
      setState(() {
        _stylists = stylists;
        _myShifts = myShifts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Handles sending a swap request. Presents a dialog where the user
  /// selects a colleague and enters an optional message. Once
  /// confirmed, the request is added to the list.
  Future<void> _requestSwap(SimpleShift shift) async {
    if (_stylists.length < 2) {
      // Cannot swap if there is only one stylist
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Es sind keine Kollegen für den Tausch verfügbar.'),
      ));
      return;
    }
    int selectedStylist = 0;
    // Exclude the current stylist from selection if possible
    final availableIndices = List<int>.generate(_stylists.length, (i) => i)
        .where((i) => i != shift.stylistIndex)
        .toList();
    String message = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tausch anfragen'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Wähle einen Kollegen aus:'),
                  DropdownButton<int>(
                    value: selectedStylist == shift.stylistIndex && availableIndices.isNotEmpty
                        ? availableIndices.first
                        : selectedStylist,
                    items: availableIndices
                        .map((i) => DropdownMenuItem<int>(
                              value: i,
                              child: Text(_stylists[i]['name'] ?? 'Stylist'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedStylist = v;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nachricht (optional)',
                    ),
                    onChanged: (text) {
                      message = text;
                    },
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
                final newRequest = SwapRequest(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  shift: shift,
                  toStylistIndex: selectedStylist,
                  message: message,
                );
                setState(() {
                  _requests.add(newRequest);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Senden'),
            ),
          ],
        );
      },
    );
  }

  /// Approves a swap request. Updates its status to accepted.
  void _approveRequest(SwapRequest request) {
    setState(() {
      request.status = SwapStatus.accepted;
    });
  }

  /// Declines a swap request. Updates its status to declined.
  void _declineRequest(SwapRequest request) {
    setState(() {
      request.status = SwapStatus.declined;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schichttausch'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stylists.isEmpty
              ? const Center(child: Text('Keine Stylisten gefunden'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meine Schichten',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _myShifts.isEmpty
                            ? const Text('Keine Schichten vorhanden.')
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _myShifts.length,
                                itemBuilder: (context, index) {
                                  final shift = _myShifts[index];
                                  final day = _weekStart.add(Duration(days: shift.dayIndex));
                                  final timeString = shift.startTime.format(context);
                                  final durationHours = (shift.duration / 60).toStringAsFixed(1);
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                        '${DateFormat('EEE dd.MM.', 'de_DE').format(day)} – $timeString (${durationHours}h)',
                                      ),
                                      subtitle: Text('Stylist: ${_stylists[shift.stylistIndex]['name'] ?? ''}'),
                                      trailing: ElevatedButton(
                                        onPressed: () => _requestSwap(shift),
                                        child: const Text('Tausch anfragen'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 24),
                        const Text(
                          'Offene Anfragen',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _requests.isEmpty
                            ? const Text('Keine Tausch‑Anfragen vorhanden.')
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _requests.length,
                                itemBuilder: (context, index) {
                                  final req = _requests[index];
                                  final shift = req.shift;
                                  final day = _weekStart.add(Duration(days: shift.dayIndex));
                                  final fromName = _stylists[shift.stylistIndex]['name'] ?? '';
                                  final toName = _stylists[req.toStylistIndex]['name'] ?? '';
                                  final statusText = req.status == SwapStatus.pending
                                      ? 'Offen'
                                      : req.status == SwapStatus.accepted
                                          ? 'Akzeptiert'
                                          : 'Abgelehnt';
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                        '${DateFormat('EEE dd.MM.', 'de_DE').format(day)} – ${shift.startTime.format(context)} (${(shift.duration / 60).toStringAsFixed(1)}h)',
                                      ),
                                      subtitle: Text('Von: $fromName  →  Zu: $toName\nNachricht: ${req.message.isNotEmpty ? req.message : '–'}'),
                                      trailing: req.status == SwapStatus.pending
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.check, color: Colors.green),
                                                  onPressed: () => _approveRequest(req),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close, color: Colors.red),
                                                  onPressed: () => _declineRequest(req),
                                                ),
                                              ],
                                            )
                                          : Text(statusText),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }
}