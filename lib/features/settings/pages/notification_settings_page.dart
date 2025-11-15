import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Allows users to customise their notification preferences.
///
/// This simple settings page provides toggles for various push
/// notifications such as booking confirmations, reminders and
/// marketing messages. Preferences are persisted using shared
/// preferences. A save button stores the current choices and
/// navigates back. This page satisfies the requirement for a
/// notifications UI following the booking flow.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _bookingConfirmed = true;
  bool _appointmentReminder = true;
  bool _marketing = false;

  // Additional preferences for channel selection and quiet hours.  The
  // push and email toggles allow users to enable or disable push and
  // email notifications globally.  Quiet hours define a start and
  // end time during which notifications should be muted.  If a time
  // is null, no quiet period is applied.
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  TimeOfDay? _quietStart;
  TimeOfDay? _quietEnd;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookingConfirmed = prefs.getBool('notif_booking_confirmed') ?? true;
      _appointmentReminder = prefs.getBool('notif_appointment_reminder') ?? true;
      _marketing = prefs.getBool('notif_marketing') ?? false;
      _pushEnabled = prefs.getBool('notif_push_enabled') ?? true;
      _emailEnabled = prefs.getBool('notif_email_enabled') ?? true;
      final startStr = prefs.getString('notif_quiet_start');
      final endStr = prefs.getString('notif_quiet_end');
      if (startStr != null && startStr.contains(':')) {
        final parts = startStr.split(':');
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _quietStart = TimeOfDay(hour: h, minute: m);
        }
      }
      if (endStr != null && endStr.contains(':')) {
        final parts = endStr.split(':');
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _quietEnd = TimeOfDay(hour: h, minute: m);
        }
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_booking_confirmed', _bookingConfirmed);
    await prefs.setBool('notif_appointment_reminder', _appointmentReminder);
    await prefs.setBool('notif_marketing', _marketing);
    await prefs.setBool('notif_push_enabled', _pushEnabled);
    await prefs.setBool('notif_email_enabled', _emailEnabled);
    if (_quietStart != null) {
      final s = _quietStart!;
      await prefs.setString('notif_quiet_start', '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}');
    } else {
      await prefs.remove('notif_quiet_start');
    }
    if (_quietEnd != null) {
      final e = _quietEnd!;
      await prefs.setString('notif_quiet_end', '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}');
    } else {
      await prefs.remove('notif_quiet_end');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Einstellungen gespeichert')),
    );
    Navigator.pop(context);
  }

  /// Opens a time picker for selecting either the start or end of the
  /// quiet period.  When a time is chosen it is stored in
  /// [_quietStart] or [_quietEnd] accordingly and the UI is updated.
  Future<void> _pickTime({required bool start}) async {
    final initial = start
        ? (_quietStart ?? const TimeOfDay(hour: 22, minute: 0))
        : (_quietEnd ?? const TimeOfDay(hour: 7, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Buchungsbestätigungen'),
            subtitle: const Text('Erhalte eine Bestätigung nach jeder Buchung'),
            value: _bookingConfirmed,
            onChanged: (value) {
              setState(() {
                _bookingConfirmed = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Termin-Erinnerungen'),
            subtitle: const Text('Erhalte Erinnerungen vor deinem Termin'),
            value: _appointmentReminder,
            onChanged: (value) {
              setState(() {
                _appointmentReminder = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Marketing-Nachrichten'),
            subtitle: const Text('Erhalte Tipps, Aktionen und Neuigkeiten'),
            value: _marketing,
            onChanged: (value) {
              setState(() {
                _marketing = value;
              });
            },
          ),
          const Divider(height: 24),
          ListTile(
            title: const Text('Ruhezeit – Start'),
            subtitle: Text(_quietStart != null
                ? _quietStart!.format(context)
                : 'Keine festgelegt'),
            trailing: const Icon(Icons.access_time),
            onTap: () => _pickTime(start: true),
          ),
          ListTile(
            title: const Text('Ruhezeit – Ende'),
            subtitle: Text(_quietEnd != null
                ? _quietEnd!.format(context)
                : 'Keine festgelegt'),
            trailing: const Icon(Icons.access_time),
            onTap: () => _pickTime(start: false),
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text('Push-Benachrichtigungen'),
            subtitle: const Text('Aktiviere oder deaktiviere Push-Notifications'),
            value: _pushEnabled,
            onChanged: (value) {
              setState(() {
                _pushEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('E-Mail-Benachrichtigungen'),
            subtitle: const Text('Aktiviere oder deaktiviere E-Mail-Notifications'),
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