import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonmanager/services/db_service.dart';

/// Represents a leave (vacation) request. Contains the list of days
/// selected, the stylist index, a status, and whether any conflicts
/// exist with scheduled shifts. In a real implementation the backend
/// would store these entries and provide more detail (e.g. comments).
class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.days,
    required this.stylistIndex,
    this.status = LeaveStatus.pending,
    this.hasConflict = false,
  });
  final String id;
  final List<DateTime> days;
  final int stylistIndex;
  LeaveStatus status;
  bool hasConflict;
}

/// Possible statuses for a leave request.
enum LeaveStatus { pending, approved, declined }

/// Page for managing leave requests. Stylists select days on a calendar
/// to submit a request. Managers see all requests and can approve or
/// decline them. Conflicts with existing shifts are indicated. This
/// implements Screen 41 of the schedule module.
class LeaveManagementPage extends StatefulWidget {
  const LeaveManagementPage({Key? key}) : super(key: key);

  @override
  State<LeaveManagementPage> createState() => _LeaveManagementPageState();
}

class _LeaveManagementPageState extends State<LeaveManagementPage> {
  /// List of stylists loaded from the database.
  List<Map<String, dynamic>> _stylists = [];

  /// Currently selected days for the new leave request.
  final Set<DateTime> _selectedDays = {};

  /// List of submitted leave requests.
  final List<LeaveRequest> _requests = [];

  /// Whether data is being loaded.
  bool _loading = false;

  /// Currently displayed month (first day of the month).
  late DateTime _currentMonth;

  /// Dummy shift days used to detect conflicts. In this example,
  /// stylists have shifts on Mondays and Wednesdays. Index 1 = Monday,
  /// 3 = Wednesday. Real data would come from the backend.
  final Set<int> _shiftWeekdayIndices = {1, 3};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _loadStylists();
  }

  /// Loads stylists from the database for displaying names with
  /// requests. For demonstration, only the first stylist can submit
  /// leave requests.
  Future<void> _loadStylists() async {
    setState(() {
      _loading = true;
    });
    try {
      final List<Map<String, dynamic>> stylists = await DbService.getStylists();
      setState(() {
        _stylists = stylists;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Calculates the number of days in the current month.
  int get _daysInMonth {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  /// Approves a leave request.
  void _approveRequest(LeaveRequest req) {
    setState(() {
      req.status = LeaveStatus.approved;
    });
  }

  /// Declines a leave request.
  void _declineRequest(LeaveRequest req) {
    setState(() {
      req.status = LeaveStatus.declined;
    });
  }

  /// Submits a new leave request for the selected days. This clears
  /// the selection afterwards. A conflict is marked if any selected
  /// day falls on a shift weekday.
  void _submitRequest() {
    if (_selectedDays.isEmpty) return;
    final daysList = _selectedDays.toList()..sort();
    final hasConflict = daysList.any((d) => _shiftWeekdayIndices.contains(d.weekday));
    final newReq = LeaveRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      days: daysList,
      stylistIndex: 0,
      hasConflict: hasConflict,
    );
    setState(() {
      _requests.add(newReq);
      _selectedDays.clear();
    });
  }

  /// Renders the calendar grid for the current month. Allows selecting
  /// individual days. Selected days are highlighted.
  Widget _buildCalendar() {
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final daysInMonth = _daysInMonth;
    // Determine how many placeholder cells are needed before the first day (Flutter's weekday starts with Monday=1)
    final leadingEmpty = (firstWeekday - 1) % 7;
    final totalCells = leadingEmpty + daysInMonth;
    // Fill grid cells with date numbers and blanks
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month and navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                  _selectedDays.clear();
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy', 'de_DE').format(_currentMonth),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                  _selectedDays.clear();
                });
              },
            ),
          ],
        ),
        // Weekday headers
        Row(
          children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.2,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              return const SizedBox.shrink();
            }
            final dayNumber = index - leadingEmpty + 1;
            final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
            final isSelected = _selectedDays.any((d) => _isSameDay(d, date));
            final isToday = _isSameDay(date, DateTime.now());
            return GestureDetector(
              onTap: () {
                setState(() {
                  final existing = _selectedDays.firstWhere((d) => _isSameDay(d, date), orElse: () => DateTime(0));
                  if (existing.year > 0) {
                    _selectedDays.remove(existing);
                  } else {
                    _selectedDays.add(date);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isToday ? Theme.of(context).colorScheme.secondary : Colors.grey.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Helper to check if two DateTime objects refer to the same calendar day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urlaubsverwaltung'),
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
                        _buildCalendar(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: _selectedDays.isNotEmpty ? _submitRequest : null,
                              child: const Text('Urlaub beantragen'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Alle Urlaubsanträge',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _requests.isEmpty
                            ? const Text('Es wurden noch keine Urlaubsanträge gestellt.')
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _requests.length,
                                itemBuilder: (context, index) {
                                  final req = _requests[index];
                                  final stylistName = req.stylistIndex < _stylists.length
                                      ? _stylists[req.stylistIndex]['name'] ?? ''
                                      : '';
                                  final dateFormatter = DateFormat('dd.MM.yyyy');
                                  final days = req.days;
                                  final rangeText = days.length == 1
                                      ? dateFormatter.format(days.first)
                                      : '${dateFormatter.format(days.first)} – ${dateFormatter.format(days.last)}';
                                  final statusText = req.status == LeaveStatus.pending
                                      ? 'Offen'
                                      : req.status == LeaveStatus.approved
                                          ? 'Genehmigt'
                                          : 'Abgelehnt';
                                  return Card(
                                    child: ListTile(
                                      title: Text('$rangeText'),
                                      subtitle: Text('Stylist: $stylistName'),
                                      leading: req.hasConflict
                                          ? const Icon(Icons.warning, color: Colors.red)
                                          : null,
                                      trailing: req.status == LeaveStatus.pending
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