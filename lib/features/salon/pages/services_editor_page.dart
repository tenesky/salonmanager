import 'package:flutter/material.dart';

import '../../../services/db_service.dart';

/// Page allowing salon owners or managers to view and edit the
/// catalogue of services.  Each service can be renamed, assigned
/// a category, price and duration.  New services may be added and
/// existing services removed.  All changes are persisted via
/// [DbService] calls.  Categories correspond to the booking
/// wizard categories (Damen/Herren/Bart/Spezial).
class ServicesEditorPage extends StatefulWidget {
  const ServicesEditorPage({Key? key}) : super(key: key);

  @override
  State<ServicesEditorPage> createState() => _ServicesEditorPageState();
}

class _ServicesEditorPageState extends State<ServicesEditorPage> {
  final List<String> _categories = ['Damen', 'Herren', 'Bart', 'Spezial'];
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final services = await DbService.getAllServices();
      setState(() {
        _services = services;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Leistungen: $e')),
      );
    }
  }

  Future<void> _showServiceDialog({Map<String, dynamic>? service}) async {
    final TextEditingController nameController =
        TextEditingController(text: service?['name'] as String? ?? '');
    final TextEditingController priceController = TextEditingController(
        text: service != null
            ? (service['price'] ?? '').toString()
            : '');
    final TextEditingController durationController = TextEditingController(
        text: service != null
            ? (service['duration'] ?? '').toString()
            : '');
    String category = service?['category'] as String? ?? _categories.first;
    final TextEditingController descriptionController = TextEditingController(
        text: service?['description'] as String? ?? '');
    final isEditing = service != null;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Leistung bearbeiten' : 'Neue Leistung'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      category = value;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Preis (€)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dauer (Minuten)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String name = nameController.text.trim();
                final String priceText = priceController.text.trim();
                final String durationText = durationController.text.trim();
                if (name.isEmpty || priceText.isEmpty || durationText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Bitte Name, Preis und Dauer angeben.')));
                  return;
                }
                final num? price = num.tryParse(priceText);
                final int? duration = int.tryParse(durationText);
                if (price == null || duration == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preis oder Dauer ungültig.')));
                  return;
                }
                try {
                  if (isEditing) {
                    await DbService.updateService(
                      id: service!['id'] as int,
                      name: name,
                      category: category,
                      price: price,
                      duration: duration,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                  } else {
                    await DbService.addService(
                      name: name,
                      category: category,
                      price: price,
                      duration: duration,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                  }
                  Navigator.of(context).pop();
                  _fetchServices();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isEditing
                          ? 'Leistung aktualisiert'
                          : 'Leistung hinzugefügt')));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Fehler: $e')));
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteService(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leistung löschen'),
        content: const Text('Möchten Sie diese Leistung wirklich löschen?'),
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
      ),
    );
    if (confirmed == true) {
      try {
        await DbService.deleteService(id);
        _fetchServices();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Leistung gelöscht')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Leistungskatalog')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _services.isEmpty
                      ? const Center(child: Text('Keine Leistungen vorhanden'))
                      : ListView.builder(
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(service['name'] as String? ?? ''),
                                subtitle: Text(
                                    '${service['category'] ?? ''} • ${service['duration']} Min • ${service['price']} €'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showServiceDialog(
                                        service: service,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteService(
                                          service['id'] as int),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Neue Leistung'),
                      onPressed: () {
                        _showServiceDialog();
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}