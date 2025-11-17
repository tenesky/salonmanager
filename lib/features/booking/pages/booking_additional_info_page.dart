import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';

/// Sixth step of the booking wizard: additional information and image upload.
///
/// On this screen customers can add free‑form notes (up to 2000 characters)
/// and upload up to five images to provide more context for their booking.
/// Uploaded images are displayed as previews with a remove button. A
/// DSGVO (GDPR) notice reminds users that any images may contain
/// personal data. Once the notes and images are provided the
/// customer can continue to the payment step. This screen implements
/// parts of the specification for Wizard 6【522868310347694†L161-L167】.
//
// Supabase Note:
//
// The images selected on this page are kept locally until the
// booking is finalised. When the user completes the wizard, the
// selected files can be uploaded to Supabase storage and a record
// created in the `booking_images` table with the `booking_id` and
// the returned `image_url`. For now we only persist the file
// paths in SharedPreferences under the key `draft_image_paths`. This
// allows subsequent wizard steps to preview the images and include
// them in the summary. Once uploaded, all team members will have
// access to the images via Supabase.
class BookingAdditionalInfoPage extends StatefulWidget {
  const BookingAdditionalInfoPage({Key? key}) : super(key: key);

  @override
  State<BookingAdditionalInfoPage> createState() => _BookingAdditionalInfoPageState();
}

class _BookingAdditionalInfoPageState extends State<BookingAdditionalInfoPage> {
  final TextEditingController _notesController = TextEditingController();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  /// Builds the persistent bottom navigation bar used throughout the app.
  /// [currentIndex] indicates the active tab. For booking pages we use index 2.
  Widget _buildBottomNav(BuildContext context, {required int currentIndex}) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: accent,
      unselectedItemColor:
          brightness == Brightness.dark ? Colors.white70 : Colors.black54,
      backgroundColor:
          brightness == Brightness.dark ? Colors.black : Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Galerie'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Buchen'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Termine'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            break;
          case 1:
            Navigator.of(context).pushNamed('/gallery');
            break;
          case 2:
            Navigator.of(context).pushNamed('/booking/select-salon');
            break;
          case 3:
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/profile/bookings');
            }
            break;
          case 4:
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/settings/profile');
            }
            break;
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Loads previously entered notes and image paths from SharedPreferences.
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final notes = prefs.getString('draft_notes');
    final images = prefs.getStringList('draft_image_paths');
    if (notes != null) {
      _notesController.text = notes;
    }
    if (images != null) {
      setState(() {
        _images.addAll(images.map((path) => XFile(path)));
      });
    }
  }

  /// Saves the current notes and image paths to SharedPreferences.
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_notes', _notesController.text);
    await prefs.setStringList('draft_image_paths', _images.map((x) => x.path).toList());
  }

  /// Picks images from the gallery up to the remaining slot count.
  Future<void> _pickImages() async {
    final remaining = 5 - _images.length;
    if (remaining <= 0) return;
    try {
      final picked = await _picker.pickMultiImage();
      if (picked != null && picked.isNotEmpty) {
        setState(() {
          // Only add up to the remaining slots
          _images.addAll(picked.take(remaining));
        });
      }
    } catch (e) {
      // silently ignore picking errors
    }
  }

  /// Removes an image from the list.
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int remaining = 5 - _images.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zusatzinfos'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator 6/8
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 6 / 8,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('6/8'),
                ],
              ),
            ),
            // Notes field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wünsche / Hinweise',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _notesController,
                    maxLength: 2000,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Weitere Details zu deiner Buchung…',
                    ),
                  ),
                ],
              ),
            ),
            // Image upload area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bilder (max. 5)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: remaining > 0 ? _pickImages : null,
                    icon: const Icon(Icons.add_a_photo),
                    label: Text('Hinzufügen ($remaining)'),
                  ),
                ],
              ),
            ),
            // Previews of selected images
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final imageFile = File(_images[index].path);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              imageFile,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Remove badge
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
            // DSGVO notice
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Hinweis: Mit dem Hochladen von Bildern erklärst du dich mit der DSGVO-konformen Verarbeitung einverstanden.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ),
            // Continue button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveDraft();
                    Navigator.of(context).pushNamed('/booking/payment');
                  },
                  child: const Text('Weiter'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, currentIndex: 2),
    );
  }
}