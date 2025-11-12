import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonmanager/services/db_service.dart';

/// Widget displaying the history of appointments and purchases for a customer.
/// It lists past bookings with date, service, stylist and revenue. Users can
/// filter by date range and service. Managers can export the list as CSV.
class CustomerHistoryTab extends StatefulWidget {
  final int customerId;
  final bool isManager;
  const CustomerHistoryTab({Key? key, required this.customerId, this.isManager = false})
      : super(key: key);

  @override
  State<CustomerHistoryTab> createState() => _CustomerHistoryTabState();
}

class _CustomerHistoryTabState extends State<CustomerHistoryTab> {
  /// List of all history entries loaded from the database.
  List<Map<String, dynamic>> _history = [];
  /// Filtered list based on date range and service selection.
  List<Map<String, dynamic>> _filtered = [];
  /// Whether data is currently being loaded.
  bool _loading = false;
  /// Available service names for filter dropdown.
  List<String> _serviceOptions = [];
  /// Currently selected service filter (null means all).
  String? _selectedService;
  /// Start and end dates for filtering history.
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Loads history entries (bookings and purchases) for the customer.
  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
    });
    try {
      final bookings = await DbService.getCustomerBookings(widget.customerId);
      final List<Map<String, dynamic>> history = [];
      final Set<String> services = {};
      for (final row in bookings) {
        // Filter by status (only completed or confirmed)
        final status = row['status'];
        if (status != null && !(status == 'completed' || status == 'confirmed')) {
          continue;
        }
        // Parse date
        DateTime dt;
        final dynamic v = row['start_datetime'];
        if (v is DateTime) {
          dt = v.toLocal();
        } else if (v is String) {
          dt = DateTime.parse(v).toLocal();
        } else {
          dt = DateTime.now();
        }
        // Extract service and stylist names from nested objects
        final dynamic service = row['services'];
        final dynamic stylist = row['stylists'];
        final String serviceName = service is Map<String, dynamic>
            ? service['name'] as String? ?? 'Service'
            : 'Service';
        final String stylistName = stylist is Map<String, dynamic>
            ? stylist['name'] as String? ?? 'Stylist'
            : 'Stylist';
        services.add(serviceName);
        history.add({
          'id': row['id'],
          'date': dt,
          'service_name': serviceName,
          'stylist_name': stylistName,
          'revenue': row['price'],
        });
      }
      setState(() {
        _history = history;
        _serviceOptions = services.toList()..sort();
      });
      _applyFilters();
    } catch (_) {
      // ignore errors
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Applies date and service filters to the history list.
  void _applyFilters() {
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(_history);
    if (_selectedService != null && _selectedService!.isNotEmpty) {
      list = list.where((e) => e['service_name'] == _selectedService).toList();
    }
    if (_fromDate != null) {
      list = list.where((e) => (e['date'] as DateTime).isAfter(_fromDate!.subtract(const Duration(days: 1))))
          .toList();
    }
    if (_toDate != null) {
      list = list.where((e) => (e['date'] as DateTime).isBefore(_toDate!.add(const Duration(days: 1))))
          .toList();
    }
    setState(() {
      _filtered = list;
    });
  }

  /// Handles CSV export of the filtered history entries.
  Future<void> _exportCsv() async {
    // Build CSV content: header + lines.
    final buffer = StringBuffer();
    buffer.writeln('Datum;Service;Stylist;Umsatz');
    final DateFormat df = DateFormat('dd.MM.yyyy HH:mm');
    for (final entry in _filtered) {
      final date = entry['date'] as DateTime;
      final service = entry['service_name'];
      final stylist = entry['stylist_name'];
      final revenue = entry['revenue'];
      buffer.writeln('${df.format(date)};$service;$stylist;$revenue');
    }
    final csvContent = buffer.toString();
    // For demonstration, we simply show a SnackBar and print the CSV to console.
    // In a real application, you'd save this to a file and trigger a download.
    debugPrint(csvContent);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV exportiert (siehe Konsole)')),
      );
    }
  }

  /// Opens a date picker and sets [_fromDate] or [_toDate].
  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? (_fromDate ?? DateTime.now().subtract(const Duration(days: 30))) : (_toDate ?? DateTime.now());
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (newDate != null) {
      setState(() {
        if (isStart) {
          _fromDate = newDate;
        } else {
          _toDate = newDate;
        }
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters row: service dropdown and date range pickers
          Row(
            children: [
              Expanded(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  hint: const Text('Leistung'),
                  value: _selectedService,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Alle Leistungen'),
                    ),
                    ..._serviceOptions.map(
                      (s) => DropdownMenuItem<String?>(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedService = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // From date picker
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isStart: true),
                  child: Text(_fromDate == null
                      ? 'Von'
                      : DateFormat('dd.MM.yyyy').format(_fromDate!)),
                ),
              ),
              const SizedBox(width: 8),
              // To date picker
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isStart: false),
                  child: Text(_toDate == null
                      ? 'Bis'
                      : DateFormat('dd.MM.yyyy').format(_toDate!)),
                ),
              ),
              if (widget.isManager)
                IconButton(
                  onPressed: _filtered.isEmpty ? null : _exportCsv,
                  icon: const Icon(Icons.download),
                  tooltip: 'Als CSV exportieren',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('Keine Historie gefunden.'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final entry = _filtered[index];
                          final DateTime dt = entry['date'];
                          final dateStr = DateFormat('dd.MM.yyyy').format(dt);
                          final timeStr = DateFormat('HH:mm').format(dt);
                          return Card(
                            child: ListTile(
                              title: Text(entry['service_name'] as String),
                              subtitle: Text('${entry['stylist_name']}\n$dateStr $timeStr'),
                              trailing: Text('${entry['revenue']} €'),
                              isThreeLine: true,
                              onTap: () {
                                // Show details in a dialog.
                                showDialog<void>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(entry['service_name'] as String),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Datum: $dateStr'),
                                          Text('Uhrzeit: $timeStr'),
                                          Text('Stylist: ${entry['stylist_name']}'),
                                          Text('Umsatz: ${entry['revenue']} €'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Schließen'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}