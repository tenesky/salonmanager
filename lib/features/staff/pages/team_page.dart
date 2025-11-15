import 'package:flutter/material.dart';
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';

/// A management page that lists all team members of the salon and
/// allows administrators or managers to change roles, activate or
/// deactivate members, and invite new colleagues by email.  Each
/// member entry shows the user id (or email if joined separately),
/// their current role and an active switch.  New invites are sent
/// via Supabase Auth and a corresponding record is added to the
/// `salon_members` table.  The list refreshes after modifications.
class TeamPage extends StatefulWidget {
  const TeamPage({Key? key}) : super(key: key);

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
    });
    try {
      final members = await DbService.getSalonMembers();
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Teammitglieder: $e')),
        );
      }
    }
  }

  Future<void> _changeRole(int index, String newRole) async {
    final member = _members[index];
    final salonId = member['salon_id'] as String?;
    final userId = member['user_id'] as String?;
    if (salonId == null || userId == null) return;
    try {
      await DbService.updateSalonMemberRole(
        salonId: salonId,
        userId: userId,
        role: newRole,
      );
      setState(() {
        _members[index]['role'] = newRole;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rollenänderung fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _toggleActive(int index, bool active) async {
    final member = _members[index];
    final salonId = member['salon_id'] as String?;
    final userId = member['user_id'] as String?;
    if (salonId == null || userId == null) return;
    try {
      await DbService.updateSalonMemberActive(
        salonId: salonId,
        userId: userId,
        active: active,
      );
      setState(() {
        _members[index]['active'] = active;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aktivierungsstatus konnte nicht geändert werden: $e')),
        );
      }
    }
  }

  Future<void> _inviteMember() async {
    String email = '';
    String role = 'stylist';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mitarbeiter einladen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                ),
                onChanged: (value) => email = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Rolle'),
                value: role,
                items: const [
                  DropdownMenuItem(value: 'salon_admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'stylist', child: Text('Stylist')),
                  DropdownMenuItem(value: 'azubi', child: Text('Azubi')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    role = val;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (email.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte E-Mail angeben')),);
                  return;
                }
                setState(() { _inviting = true; });
                try {
                  final userId = await AuthService.inviteUser(email.trim());
                  if (userId != null) {
                    // Insert new member record; we assign the first salon_id from existing members or ask the user later.
                    String salonId;
                    if (_members.isNotEmpty) {
                      salonId = _members.first['salon_id'] as String;
                    } else {
                      // Without existing members we cannot determine salonId. Show a warning.
                      throw Exception('Kein Salon zum Hinzufügen gefunden.');
                    }
                    await DbService.addSalonMember(
                      salonId: salonId,
                      userId: userId,
                      role: role,
                      active: true,
                    );
                    await _loadMembers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Einladung gesendet an $email')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Einladung konnte nicht gesendet werden')),);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Einladen: $e')),
                  );
                } finally {
                  if (mounted) {
                    setState(() { _inviting = false; });
                  }
                }
              },
              child: const Text('Einladen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teamverwaltung'),
        actions: [
          IconButton(
            icon: _inviting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add),
            tooltip: 'Mitarbeiter einladen',
            onPressed: _inviting ? null : _inviteMember,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(child: Text('Keine Teammitglieder gefunden'))
              : ListView.separated(
                  itemCount: _members.length,
                  separatorBuilder: (context, index) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final role = member['role'] as String? ?? 'stylist';
                    final active = member['active'] as bool? ?? true;
                    final userId = member['user_id'] as String? ?? '';
                    return ListTile(
                      title: Text(userId),
                      subtitle: Text('Rolle: $role'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButton<String>(
                            value: role,
                            underline: Container(),
                            items: const [
                              DropdownMenuItem(value: 'salon_admin', child: Text('Admin')),
                              DropdownMenuItem(value: 'manager', child: Text('Manager')),
                              DropdownMenuItem(value: 'stylist', child: Text('Stylist')),
                              DropdownMenuItem(value: 'azubi', child: Text('Azubi')),
                            ],
                            onChanged: (val) {
                              if (val != null && val != role) {
                                _changeRole(index, val);
                              }
                            },
                          ),
                          Switch(
                            value: active,
                            onChanged: (val) {
                              _toggleActive(index, val);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}