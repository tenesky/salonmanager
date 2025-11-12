import 'package:flutter/material.dart';
import 'package:salonmanager/services/db_service.dart';

/// Page that allows a stylist or manager to cancel one or more
/// appointments at once. A selection list shows upcoming or
/// confirmed bookings; the user can select multiple entries and
/// specify a cancellation reason via a drop‑down menu with common
/// reasons (e.g. sickness, overbooking). An optional text field
/// allows entering a custom explanation. After sending the
/// cancellations the selected bookings are removed from the list
/// and a confirmation snackbar is shown. This implements
/// Screens 32–33 of the specification, which require a mask with
/// predefined reasons and mass selection【219863215679107†L61-L63】.
class CancelBookingsPage extends StatefulWidget {
  const CancelBookingsPage({Key? key}) : super(key: key);

  @override
  State<CancelBookingsPage> createState() => _CancelBookingsPageState();
}

class _CancelBookingsPageState extends State<CancelBookingsPage> {
  /// List of appointments eligible for cancellation. Populated from
  /// the database when the page is initialised. Each entry
  /// contains: id, datetime, customer, service, stylist and status.
  List<Map<String, dynamic>> _appointments = [];
  
  /// Whether appointments are currently being loaded from the database.
  bool _loading = false;

  /// Currently selected appointment ids for cancellation.
  final Set<int> _selected = {};

  /// The selected cancellation reason. Must be chosen before sending.
  String? _selectedReason;

  /// Controller for optional free text reason.
  final TextEditingController _customReasonController = TextEditingController();

  /// List of predefined cancellation reasons.
  final List<String> _reasons = [
    'Krankheit',
    'Überlastung',
    'Technische Probleme',
    'Sonstiges',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  /// Load upcoming bookings that may be cancelled. Selects all
  /// bookings with status 'pending' or 'confirmed' whose start date
  /// and time are equal to or later than the current time. Joins
  /// customers, services and stylists for names. The results are
  /// stored in [_appointments].
  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
    });
    try {
      final loaded = await DbService.getCancellableAppointments();
      setState(() {
        _appointments = loaded;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Handles submission of the cancellations. For each selected booking
  /// record the cancellation reason and optional custom message in
  /// the database and update the booking status to 'canceled'. After
  /// completing the updates, remove cancelled bookings from the local
  /// list and reset the selection and reason fields.
  Future<void> _sendCancellations() async {
    final selectedIds = _selected.toList();
    final reason = _selectedReason;
    final message = _customReasonController.text;
    if (selectedIds.isEmpty || reason == null || reason.isEmpty) {
      return;
    }
    try {
      await DbService.cancelBookings(
        ids: selectedIds,
        reason: reason,
        message: message,
      );
      setState(() {
        _appointments.removeWhere((appt) => _selected.contains(appt['id']));
        _selected.clear();
        _selectedReason = null;
        _customReasonController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absagen verschickt.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Senden der Absagen.')),
      );
    }
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  /// Returns true if the send button should be disabled (i.e. no
  /// appointments selected or no reason chosen).
  bool get _isSendDisabled {
    return _selected.isEmpty || _selectedReason == null || _selectedReason!.isEmpty;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termine absagen'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Appointment selection list
            Text(
              'Termine auswählen',
              // Use titleLarge for section headings (replaces headline6).
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_appointments.isEmpty)
              const Text('Keine Termine vorhanden.'),
            for (final appt in _appointments)
              CheckboxListTile(
                value: _selected.contains(appt['id'] as int),
                onChanged: (bool? value) {
                  setState(() {
                    final id = appt['id'] as int;
                    if (value == true) {
                      _selected.add(id);
                    } else {
                      _selected.remove(id);
                    }
                  });
                },
                title: Text(
                  '${(appt['datetime'] as DateTime).day.toString().padLeft(2, '0')}.${(appt['datetime'] as DateTime).month.toString().padLeft(2, '0')} • ${(appt['datetime'] as DateTime).hour.toString().padLeft(2, '0')}:${(appt['datetime'] as DateTime).minute.toString().padLeft(2, '0')}',
                ),
                subtitle: Text('${appt['customer']} – ${appt['service']} (Stylist: ${appt['stylist']})'),
              ),
            const SizedBox(height: 24),
            // Reason selection
            Text(
              'Grund der Absage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              hint: const Text('Bitte einen Grund wählen'),
              items: _reasons
                  .map((reason) => DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            ),
            const SizedBox(height: 12),
            // Optional free text field
            TextField(
              controller: _customReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Optionaler Freitext (optional)',
              ),
            ),
            const SizedBox(height: 24),
            // Send button
            ElevatedButton(
              onPressed: _isSendDisabled ? null : _sendCancellations,
              child: const Text('Absage senden'),
            ),
          ],
        ),
      ),
    );
  }
}