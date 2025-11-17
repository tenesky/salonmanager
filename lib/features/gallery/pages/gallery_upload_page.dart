import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';

/// A page that allows users to upload a new image to the public gallery.
///
/// Users can pick an image from their device, provide an optional
/// description and choose optional metadata (length, style and colour).
/// When the form is submitted, the image is uploaded to Supabase
/// storage and a new row is inserted into the `gallery_images` table.
class GalleryUploadPage extends StatefulWidget {
  const GalleryUploadPage({Key? key}) : super(key: key);

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _lengthOptions = const ['Kurz', 'Mittel', 'Lang'];
  final List<String> _styleOptions = const ['Klassisch', 'Modern', 'Trend'];
  final List<String> _colourOptions = const ['Blond', 'Braun', 'Rot'];

  String? _selectedLength;
  String? _selectedStyle;
  String? _selectedColour;
  XFile? _pickedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _pickedFile = file;
      });
    }
  }

  Future<void> _submit() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle ein Bild aus.')),
      );
      return;
    }
    if (!AuthService.isLoggedIn()) {
      // Require authentication before posting
      Navigator.of(context).pushNamed('/login');
      return;
    }
    setState(() {
      _isUploading = true;
    });
    try {
      final bytes = await _pickedFile!.readAsBytes();
      // Upload the image to Supabase storage
      final String storagePath =
          await DbService.uploadGalleryImage(bytes, _pickedFile!.name);
      // Insert metadata into gallery_images table
      await DbService.addGalleryImage(
        url: storagePath,
        description: _descriptionController.text.trim(),
        length: _selectedLength,
        style: _selectedStyle,
        colour: _selectedColour,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bild erfolgreich hochgeladen!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hochladen: \$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bild hochladen'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.dividerColor.withOpacity(0.1),
                      ),
                      child: _pickedFile == null
                          ? const Center(
                              child: Icon(Icons.add_a_photo, size: 48),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_pickedFile!.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _selectedLength,
                    decoration: const InputDecoration(labelText: 'Länge'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Alle')),
                      ..._lengthOptions.map(
                        (opt) => DropdownMenuItem<String?>(value: opt, child: Text(opt)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedLength = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedStyle,
                    decoration: const InputDecoration(labelText: 'Stil'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Alle')),
                      ..._styleOptions.map(
                        (opt) => DropdownMenuItem<String?>(value: opt, child: Text(opt)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedStyle = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedColour,
                    decoration: const InputDecoration(labelText: 'Farbe'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Alle')),
                      ..._colourOptions.map(
                        (opt) => DropdownMenuItem<String?>(value: opt, child: Text(opt)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedColour = value),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submit,
                      child: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Posten'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Add persistent bottom navigation bar with the gallery tab selected (index 1).
      bottomNavigationBar: _buildBottomNav(context, currentIndex: 1),
    );
  }

  /// Builds a bottom navigation bar.  Uses [currentIndex] to select
  /// the active tab.  This page uses index 1 for the gallery.
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
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Buchen'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Termine'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
            break;
          case 1:
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/gallery', (route) => false);
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
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/settings/profile', (route) => false);
            break;
        }
      },
    );
  }
}