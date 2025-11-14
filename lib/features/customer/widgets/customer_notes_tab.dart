import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonmanager/services/db_service.dart';

/// Widget for displaying and managing customer notes. Allows stylists to
/// add, edit, delete and search through internal notes per customer.
class CustomerNotesTab extends StatefulWidget {
  final int customerId;
  const CustomerNotesTab({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerNotesTab> createState() => _CustomerNotesTabState();
}

class _CustomerNotesTabState extends State<CustomerNotesTab> {
  /// All notes loaded from the database.
  List<Map<String, dynamic>> _notes = [];
  /// Notes filtered by search query.
  List<Map<String, dynamic>> _filtered = [];
  /// Controller for the search input.
  final TextEditingController _searchController = TextEditingController();
  /// Whether notes are currently being loaded.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches notes from the database for the given customer.
  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
    });
    try {
      final results = await DbService.getCustomerNotes(widget.customerId);
      final List<Map<String, dynamic>> notes = [];
      for (final row in results) {
        DateTime dt;
        final dynamic v = row['created_at'];
        if (v is DateTime) {
          dt = v.toLocal();
        } else if (v is String) {
          dt = DateTime.parse(v).toLocal();
        } else {
          dt = DateTime.now();
        }
        notes.add({
          'id': row['id'],
          'content': row['content'] as String,
          'author': row['author'] as String?,
          'created_at': dt,
        });
      }
      setState(() {
        _notes = notes;
      });
      _applySearch();
    } catch (_) {
      // ignore errors
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Filters notes by the search query.
  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filtered = List<Map<String, dynamic>>.from(_notes);
      });
    } else {
      final filtered = _notes
          .where((n) => (n['content'] as String).toLowerCase().contains(query))
          .toList();
      setState(() {
        _filtered = filtered;
      });
    }
  }

  /// Opens a dialog to add or edit a note. If [note] is null a new note
  /// will be created, otherwise the existing note is updated.
  Future<void> _showNoteDialog({Map<String, dynamic>? note}) async {
    final bool isEditing = note != null;
    final TextEditingController controller = TextEditingController(
      text: isEditing ? note!['content'] as String : '',
    );
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Notiz bearbeiten' : 'Neue Notiz'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Notiz hier eingeben...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = controller.text.trim();
                if (content.isEmpty) return;
                if (isEditing) {
                  await _updateNote(note!['id'] as int, content);
                } else {
                  await _addNote(content);
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(isEditing ? 'Speichern' : 'Hinzufügen'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  /// Inserts a new note into the database.
  Future<void> _addNote(String content) async {
    try {
      // In a real application, author should be the logged in stylist's identifier
      await DbService.addCustomerNote(
        customerId: widget.customerId,
        author: 'Stylist',
        content: content,
      );
      await _loadNotes();
    } catch (_) {
      // ignore errors
    }
  }

  /// Updates an existing note in the database.
  Future<void> _updateNote(int id, String content) async {
    try {
      await DbService.updateCustomerNote(id: id, content: content);
      await _loadNotes();
    } catch (_) {
      // ignore errors
    }
  }

  /// Deletes a note from the database.
  Future<void> _deleteNote(int id) async {
    try {
      await DbService.deleteCustomerNote(id);
      await _loadNotes();
    } catch (_) {
      // ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar and add button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Suche',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showNoteDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Notiz'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('Keine Notizen.'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final note = _filtered[index];
                        final DateTime dt = note['created_at'] as DateTime;
                        final String dateStr = DateFormat('dd.MM.yyyy HH:mm').format(dt);
                        final String content = note['content'] as String;
                        final String author = note['author'] ?? 'Unbekannt';
                        return Card(
                          child: ListTile(
                            title: Text(
                              content.length > 100 ? content.substring(0, 100) + '…' : content,
                            ),
                            subtitle: Text('$author • $dateStr'),
                            onTap: () => _showNoteDialog(note: note),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final bool confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Notiz löschen?'),
                                          content: const Text('Möchtest du diese Notiz wirklich löschen?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Abbrechen'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text('Löschen'),
                                            ),
                                          ],
                                        );
                                      },
                                    ) ??
                                    false;
                                if (confirm) {
                                  await _deleteNote(note['id'] as int);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}