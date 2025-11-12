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
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_booking_confirmed', _bookingConfirmed);
    await prefs.setBool('notif_appointment_reminder', _appointmentReminder);
    await prefs.setBool('notif_marketing', _marketing);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Einstellungen gespeichert')),
    );
    Navigator.pop(context);
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