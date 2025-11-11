import 'package:flutter/material.dart';

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
  /// Sample list of appointments that can be cancelled. Each map
  /// contains an id, date/time, customer, service, stylist and
  /// status. In a real application this data would come from the
  /// backend and include unique identifiers for each appointment.
  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 1,
      'datetime': DateTime(2025, 11, 14, 9, 0),
      'customer': 'Anna Schmidt',
      'service': 'Haarschnitt',
      'stylist': 'Max',
      'status': 'confirmed',
    },
    {
      'id': 2,
      'datetime': DateTime(2025, 11, 14, 11, 30),
      'customer': 'Peter Müller',
      'service': 'Färben',
      'stylist': 'Sofia',
      'status': 'confirmed',
    },
    {
      'id': 3,
      'datetime': DateTime(2025, 11, 15, 14, 0),
      'customer': 'Julia Weber',
      'service': 'Styling',
      'stylist': 'Tom',
      'status': 'pending',
    },
    {
      'id': 4,
      'datetime': DateTime(2025, 11, 16, 10, 0),
      'customer': 'Lena Becker',
      'service': 'Balayage',
      'stylist': 'Anna',
      'status': 'confirmed',
    },
  ];

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
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  /// Returns true if the send button should be disabled (i.e. no
  /// appointments selected or no reason chosen).
  bool get _isSendDisabled {
    return _selected.isEmpty || _selectedReason == null || _selectedReason!.isEmpty;
  }

  /// Handles submission of the cancellations. Removes the selected
  /// appointments from the list and shows a confirmation.
  void _sendCancellations() {
    setState(() {
      _appointments.removeWhere((appt) => _selected.contains(appt['id']));
      _selected.clear();
      _selectedReason = null;
      _customReasonController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Absagen verschickt.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termine absagen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Appointment selection list
            Text(
              'Termine auswählen',
              style: Theme.of(context).textTheme.headline6,
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
              style: Theme.of(context).textTheme.headline6,
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