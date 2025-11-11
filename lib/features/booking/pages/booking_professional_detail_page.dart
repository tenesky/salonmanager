import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Detail page for stylists to view and edit booking information.
///
/// This page extends the basic booking detail view by allowing the
/// professional to modify the price and duration for each service
/// within a booking, add internal notes and upload images (for
/// example, to store before/after photos). It corresponds to
/// Screen 30 in the specification, which requires editable
/// service details and note/image fields【219863215679107†L39-L47】.
class BookingProfessionalDetailPage extends StatefulWidget {
  /// Expects a booking map containing keys such as `customerName`,
  /// `services`, `date`, `time`, `notes`, `imagePaths` and `stylistName`.
  final Map<String, dynamic> booking;
  const BookingProfessionalDetailPage({Key? key, required this.booking}) : super(key: key);

  @override
  State<BookingProfessionalDetailPage> createState() => _BookingProfessionalDetailPageState();
}

class _BookingProfessionalDetailPageState extends State<BookingProfessionalDetailPage> {
  late List<Map<String, dynamic>> _services;
  late TextEditingController _notesController;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialise services from booking data. Each service entry should
    // include a `name`, `price` and `duration` field. If the booking
    // does not provide services, start with an empty list.
    final List<dynamic>? servicesDynamic = widget.booking['services'] as List<dynamic>?;
    _services = servicesDynamic
            ?.map((e) => {
                  'name': e['name'] ?? '',
                  'price': e['price'] ?? 0.0,
                  'duration': e['duration'] ?? 0,
                })
            .toList() ??
        [];
    // Notes controller initialised with existing notes (if any).
    _notesController = TextEditingController(text: widget.booking['notes']?.toString() ?? '');
    // Load existing images from file paths if provided.
    final List<dynamic>? imagePaths = widget.booking['imagePaths'] as List<dynamic>?;
    if (imagePaths != null) {
      for (final path in imagePaths) {
        if (path is String) {
          _images.add(XFile(path));
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Opens a dialog allowing the stylist to edit the price and duration
  /// for a given service. The [index] identifies which service in
  /// [_services] to modify. After the user confirms, the service
  /// details are updated via setState.
  Future<void> _editService(int index) async {
    final service = _services[index];
    final priceController = TextEditingController(text: service['price'].toString());
    final durationController = TextEditingController(text: service['duration'].toString());
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Leistung bearbeiten: ${service['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Preis (€)',
                ),
              ),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dauer (Minuten)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? newPrice = double.tryParse(priceController.text);
                final int? newDuration = int.tryParse(durationController.text);
                setState(() {
                  if (newPrice != null) _services[index]['price'] = newPrice;
                  if (newDuration != null) _services[index]['duration'] = newDuration;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leistung aktualisiert.')),
                );
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  /// Allows the stylist to pick images from the gallery. Uses the
  /// [ImagePicker] to allow multiple selections. Selected images are
  /// appended to [_images] and displayed in the UI.
  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked != null && picked.isNotEmpty) {
        setState(() {
          _images.addAll(picked);
        });
      }
    } catch (_) {
      // Ignore errors silently.
    }
  }

  /// Removes an image at the given index from the list of selected
  /// images.
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  /// Builds a card widget displaying customer and appointment details.
  Widget _buildCustomerCard() {
    final String customerName = widget.booking['customerName']?.toString() ?? '–';
    final String stylistName = widget.booking['stylistName']?.toString() ?? '–';
    final String date = widget.booking['date']?.toString() ?? '';
    final String time = widget.booking['time']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stylistName.isNotEmpty) Text('Stylist: $stylistName'),
            if (date.isNotEmpty || time.isNotEmpty) Text('$date $time'),
          ],
        ),
      ),
    );
  }

  /// Builds a card containing a list of all services for the booking.
  Widget _buildServicesCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.design_services),
                SizedBox(width: 8),
                Text('Leistungen', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_services.isEmpty)
              const Text('Keine Leistungen hinterlegt.'),
            for (int i = 0; i < _services.length; i++)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                title: Text(_services[i]['name']?.toString() ?? ''),
                subtitle: Text(
                  'Preis: ${_services[i]['price'].toStringAsFixed(2)} € • Dauer: ${_services[i]['duration']} min',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editService(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a card for the stylist to enter or edit internal notes.
  Widget _buildNotesCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.notes),
                SizedBox(width: 8),
                Text('Notizen', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Interne Notizen (nur für Stylisten sichtbar)',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notizen gespeichert.')),
                  );
                },
                child: const Text('Notizen speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card to display selected images and allow adding/removing
  /// additional photos. Uses a horizontal ListView for thumbnails and
  /// a button to pick more images from the gallery.
  Widget _buildImagesCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.photo),
                SizedBox(width: 8),
                Text('Bilder', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_images.length} ausgewählt'),
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Hinzufügen'),
                ),
              ],
            ),
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final file = File(_images[index].path);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              file,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termin‑Detail (Profi)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerCard(),
            _buildServicesCard(),
            _buildNotesCard(),
            _buildImagesCard(),
          ],
        ),
      ),
    );
  }
}