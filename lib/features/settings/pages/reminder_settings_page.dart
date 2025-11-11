import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A settings page that allows stylists or managers to configure automatic
/// appointment reminders. Users can decide how far in advance they wish
/// to send reminders (in hours or days) and enable or disable different
/// notification channels such as Push and E‑Mail. These settings
/// correspond to the Reminder‑Konfiguration described in the Realisierungsplan
/// where managers can set global reminder time points and channels【73678961014422†L1444-L1447】.
class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({Key? key}) : super(key: key);

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  /// Number of hours or days before the appointment when a reminder should be
  /// sent. The interpretation depends on [_unit].
  int _reminderValue = 24;

  /// Unit for the reminder: either 'hours' or 'days'. When set to 'days'
  /// the [_reminderValue] is multiplied by 24 when stored.
  String _unit = 'hours';

  /// Whether push notifications should be sent.
  bool _pushEnabled = true;

  /// Whether e‑mail notifications should be sent.
  bool _emailEnabled = true;

  /// Load previously saved preferences from [SharedPreferences]. Defaults
  /// to 24 hours, push on and email on. If no preferences exist the
  /// defaults are used.
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('reminder_push_enabled') ?? true;
      _emailEnabled = prefs.getBool('reminder_email_enabled') ?? true;
      final storedUnit = prefs.getString('reminder_unit');
      if (storedUnit == 'hours' || storedUnit == 'days') {
        _unit = storedUnit;
      }
      final storedValue = prefs.getInt('reminder_value');
      if (storedValue != null && storedValue > 0) {
        _reminderValue = storedValue;
      }
    });
  }

  /// Save the current reminder settings to [SharedPreferences]. The value is
  /// stored as hours and the unit separately. After saving a snackbar
  /// confirms the changes and the page is closed. In a real application
  /// these settings would be sent to the server so reminders can be
  /// scheduled accordingly【73678961014422†L1502-L1505】.
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_push_enabled', _pushEnabled);
    await prefs.setBool('reminder_email_enabled', _emailEnabled);
    await prefs.setString('reminder_unit', _unit);
    await prefs.setInt('reminder_value', _reminderValue);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erinnerungen gespeichert')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Determine the maximum slider value based on the selected unit. For
    // hours we allow up to 72 (three days), and for days up to 14 days.
    final maxValue = _unit == 'hours' ? 72 : 14;
    final divisions = maxValue - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder-Konfiguration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Zeitpunkt der Erinnerung',
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dropdown to choose hours or days
              Expanded(
                child: DropdownButton<String>(
                  value: _unit,
                  items: const [
                    DropdownMenuItem(value: 'hours', child: Text('Stunden')),
                    DropdownMenuItem(value: 'days', child: Text('Tage')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _unit = value;
                      // Ensure value does not exceed new max when switching units.
                      if (_unit == 'hours' && _reminderValue > 72) {
                        _reminderValue = 72;
                      } else if (_unit == 'days' && _reminderValue > 14) {
                        _reminderValue = 14;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$_reminderValue ${_unit == 'hours' ? 'Std.' : 'Tage'}',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ],
          ),
          Slider(
            min: 1,
            max: maxValue.toDouble(),
            divisions: divisions,
            label: _reminderValue.toString(),
            value: _reminderValue.toDouble(),
            onChanged: (value) {
              setState(() {
                _reminderValue = value.round();
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Kanäle',
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Push‑Benachrichtigung'),
            subtitle: const Text('Aktiviere oder deaktiviere Push‑Erinnerungen'),
            value: _pushEnabled,
            onChanged: (value) {
              setState(() {
                _pushEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('E‑Mail‑Erinnerung'),
            subtitle: const Text('Aktiviere oder deaktiviere E‑Mail‑Erinnerungen'),
            value: _emailEnabled,
            onChanged: (value) {
              setState(() {
                _emailEnabled = value;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _savePreferences,
          child: const Text('Speichern'),
        ),
      ),
    );
  }
}