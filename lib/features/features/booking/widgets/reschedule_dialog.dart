import 'package:flutter/material.dart';

/// A dialog allowing a stylist to propose up to three alternative
/// appointment times for a booking. Each proposal consists of a
/// date and a time, which can be picked using the built‑in
/// `showDatePicker` and `showTimePicker` widgets. When the user
/// taps “Vorschlag senden” the selected options are returned to
/// the caller. If no proposals are selected the list contains
/// null values.
class RescheduleDialog extends StatefulWidget {
  const RescheduleDialog({Key? key}) : super(key: key);

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  final List<DateTime?> _dates = List<DateTime?>.filled(3, null);
  final List<TimeOfDay?> _times = List<TimeOfDay?>.filled(3, null);

  /// Opens a date picker for the proposal at [index]. The chosen
  /// date is stored in [_dates] if the user confirms.
  Future<void> _pickDate(int index) async {
    final DateTime now = DateTime.now();
    final DateTime initial = _dates[index] ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dates[index] = picked;
      });
    }
  }

  /// Opens a time picker for the proposal at [index]. The chosen
  /// time is stored in [_times] if the user confirms.
  Future<void> _pickTime(int index) async {
    final TimeOfDay nowTime = TimeOfDay.now();
    final TimeOfDay initial = _times[index] ?? nowTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        _times[index] = picked;
      });
    }
  }

  /// Returns a human‑readable string representation for a proposal at
  /// [index], or “Nicht gesetzt” if either date or time is null.
  String _proposalLabel(int index) {
    final DateTime? date = _dates[index];
    final TimeOfDay? time = _times[index];
    if (date == null || time == null) {
      return 'Keine Auswahl';
    }
    final String dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final String timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return '$dateStr um $timeStr';
    }

  /// Sends the proposals back to the caller. The result is a list
  /// containing maps with `date` and `time` keys when both are set;
  /// otherwise null entries are inserted. The dialog is closed and
  /// the result returned via Navigator.pop.
  void _sendProposals() {
    final List<Map<String, dynamic>?> proposals = [];
    for (int i = 0; i < 3; i++) {
      final DateTime? d = _dates[i];
      final TimeOfDay? t = _times[i];
      if (d != null && t != null) {
        proposals.add({
          'date': DateTime(d.year, d.month, d.day),
          'time': TimeOfDay(hour: t.hour, minute: t.minute),
        });
      } else {
        proposals.add(null);
      }
    }
    Navigator.of(context).pop(proposals);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Umbuchungs‑Vorschlag'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Wähle bis zu drei alternative Termine:'),
            const SizedBox(height: 12),
            for (int i = 0; i < 3; i++)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vorschlag ${i + 1}: ${_proposalLabel(i)}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDate(i),
                          child: const Text('Datum wählen'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(i),
                          child: const Text('Zeit wählen'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _sendProposals,
          child: const Text('Vorschlag senden'),
        ),
      ],
    );
  }
}