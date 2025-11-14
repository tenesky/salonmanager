import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salonmanager/services/db_service.dart';

/// Detail page for stylists to view and edit booking information.
///
/// Rather than requiring the entire booking data to be passed in via
/// arguments, this page accepts a booking identifier and loads the
/// corresponding record from the database. It allows editing the
/// price and duration for the booked service, adding internal notes
/// and uploading images (images are not persisted in this demo). This
/// corresponds to Screen 30 in the specification【219863215679107†L39-L47】.
class BookingProfessionalDetailPage extends StatefulWidget {
  /// The unique ID of the booking to display.
  final int bookingId;
  const BookingProfessionalDetailPage({Key? key, required this.bookingId}) : super(key: key);

  @override
  State<BookingProfessionalDetailPage> createState() => _BookingProfessionalDetailPageState();
}

class _BookingProfessionalDetailPageState extends State<BookingProfessionalDetailPage> {
  /// Holds basic booking info: customerName, stylistName, date, time.
  Map<String, dynamic>? _bookingInfo;
  /// Holds the service associated with the booking. In this simplified
  /// schema a booking has only one service. Each map contains
  /// `name`, `price` and `duration` fields.
  List<Map<String, dynamic>> _services = [];
  /// Controller for internal notes.
  late TextEditingController _notesController;
  /// List of selected images (not saved to the database in this demo).
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  /// Loading indicator while data is fetched.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadBooking();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Fetch booking details from the database. Joins with related
  /// tables to get human‑readable names and the booked service.
  Future<void> _loadBooking() async {
    setState(() {
      _loading = true;
    });
    try {
      final detail = await DbService.getBookingDetail(widget.bookingId);
      if (detail != null) {
        _bookingInfo = {
          'customerName': detail['customerName'],
          'stylistName': detail['stylistName'],
          'date': detail['date'],
          'time': detail['time'],
        };
        _services = List<Map<String, dynamic>>.from(detail['services'] as List);
        _notesController.text = detail['notes']?.toString() ?? '';
      }
    } catch (_) {
      // ignore errors
    }
    setState(() {
      _loading = false;
    });
  }

  /// Opens a dialog to edit the price and duration of the single service.
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double? newPrice = double.tryParse(priceController.text);
                final int? newDuration = int.tryParse(durationController.text);
                if (newPrice != null && newDuration != null) {
                  setState(() {
                    _services[index]['price'] = newPrice;
                    _services[index]['duration'] = newDuration;
                  });
                  // Persist the changes to the database.
                  try {
                    await DbService.updateBookingPriceDuration(
                        bookingId: widget.bookingId,
                        price: newPrice,
                        duration: newDuration);
                  } catch (_) {
                    // ignore errors
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leistung aktualisiert.')),
                  );
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  /// Handles image picking. In this demo images are kept only in memory.
  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked != null && picked.isNotEmpty) {
        setState(() {
          _images.addAll(picked);
        });
      }
    } catch (_) {
      // ignore
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  /// Saves notes to the database.
  Future<void> _saveNotes() async {
    final String notes = _notesController.text;
    try {
      await DbService.updateBookingNotes(
        bookingId: widget.bookingId,
        notes: notes,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notizen gespeichert.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Speichern der Notizen.')),
      );
    }
  }

  Widget _buildCustomerCard() {
    if (_bookingInfo == null) {
      return const SizedBox.shrink();
    }
    final String customerName = _bookingInfo!['customerName'] ?? '';
    final String stylistName = _bookingInfo!['stylistName'] ?? '';
    final String date = _bookingInfo!['date'] ?? '';
    final String time = _bookingInfo!['time'] ?? '';
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
                Text('Leistung', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_services.isEmpty)
              const Text('Keine Leistung hinterlegt.'),
            for (int i = 0; i < _services.length; i++)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                title: Text(_services[i]['name']?.toString() ?? ''),
                subtitle: Text(
                  'Preis: ${(_services[i]['price'] as num).toStringAsFixed(2)} € • Dauer: ${_services[i]['duration']} min',
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
                onPressed: _saveNotes,
                child: const Text('Notizen speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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