import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../services/db_service.dart';

/// Page allowing salon owners to edit the salon's profile.  This
/// includes uploading a logo, selecting branding colours, defining
/// the order of layout blocks on the public salon page, specifying
/// opening hours and toggling custom legal text.  The page
/// retrieves the current salon record based on the logged in user
/// (owner_id) and writes updates back to the database via
/// [DbService.updateSalonProfile].
class SalonProfilePage extends StatefulWidget {
  const SalonProfilePage({Key? key}) : super(key: key);

  @override
  State<SalonProfilePage> createState() => _SalonProfilePageState();
}

class _SalonProfilePageState extends State<SalonProfilePage> {
  Map<String, dynamic>? _salon;
  bool _loading = true;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _legalTextController = TextEditingController();
  Color _primaryColor = Colors.black;
  Color _accentColor = Colors.amber;
  List<String> _blocks = ['services', 'gallery', 'team'];
  bool _useDefaultLegal = true;
  String? _logoUrl;
  Uint8List? _newLogoBytes;
  String? _newLogoFileName;

  @override
  void initState() {
    super.initState();
    _fetchSalon();
  }

  Future<void> _fetchSalon() async {
    try {
      final data = await DbService.getSalonProfile();
      if (data != null) {
        setState(() {
          _salon = data;
          _nameController.text = data['name'] as String? ?? '';
          _addressController.text = data['address'] as String? ?? '';
          _phoneController.text = data['phone'] as String? ?? '';
          _websiteController.text = data['website'] as String? ?? '';
          _openingHoursController.text = data['opening_hours'] as String? ?? '';
          _legalTextController.text = data['legal_text'] as String? ?? '';
          final primaryStr = data['primary_color'] as String?;
          final accentStr = data['accent_color'] as String?;
          if (primaryStr != null && primaryStr.isNotEmpty) {
            _primaryColor = _parseColor(primaryStr);
          }
          if (accentStr != null && accentStr.isNotEmpty) {
            _accentColor = _parseColor(accentStr);
          }
          final blockOrder = data['block_order'] as String?;
          if (blockOrder != null && blockOrder.isNotEmpty) {
            _blocks = blockOrder.split(',');
          }
          _useDefaultLegal = (data['use_default_legal_text'] as bool?) ?? true;
          _logoUrl = data['logo_url'] as String?;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Parses a colour string of the form '#RRGGBB' into a [Color].
  Color _parseColor(String value) {
    String hex = value;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// Converts a [Color] to a hex string of the form '#RRGGBB'.
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Opens the image picker to select a new logo from the gallery.
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newLogoBytes = bytes;
        _newLogoFileName = picked.name;
      });
    }
  }

  /// Opens a colour picker dialog to choose a new primary or accent colour.
  Future<void> _pickColour({required bool primary}) async {
    Color tempColor = primary ? _primaryColor : _accentColor;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(primary ? 'Primärfarbe wählen' : 'Akzentfarbe wählen'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (c) {
              tempColor = c;
            },
            showLabel: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (primary) {
                  _primaryColor = tempColor;
                } else {
                  _accentColor = tempColor;
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
  }

  /// Saves the current form values to the database.  If a new logo has
  /// been selected it is uploaded before updating the salon record.  A
  /// snackbar is displayed on success or error.
  Future<void> _saveProfile() async {
    final salonId = _salon?['id']?.toString();
    if (salonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Salon gefunden.')),
      );
      return;
    }
    String? logoUrl = _logoUrl;
    try {
      // Upload new logo if provided
      if (_newLogoBytes != null && _newLogoFileName != null) {
        logoUrl = await DbService.uploadSalonLogo(
            _newLogoBytes!.toList(), _newLogoFileName!);
      }
      await DbService.updateSalonProfile(
        salonId: salonId,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        primaryColor: _colorToHex(_primaryColor),
        accentColor: _colorToHex(_accentColor),
        blockOrder: _blocks.join(','),
        openingHours: _openingHoursController.text.trim().isEmpty
            ? null
            : _openingHoursController.text.trim(),
        legalText: _useDefaultLegal ? null : _legalTextController.text.trim(),
        useDefaultLegalText: _useDefaultLegal,
        logoUrl: logoUrl,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salonprofil gespeichert.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Salonprofil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salonprofil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo section
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: _newLogoBytes != null
                      ? MemoryImage(_newLogoBytes!)
                      : (_logoUrl != null && _logoUrl!.isNotEmpty)
                          ? NetworkImage(_logoUrl!) as ImageProvider
                          : null,
                  child: (_newLogoBytes == null && (_logoUrl == null || _logoUrl!.isEmpty))
                      ? const Icon(Icons.store, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.upload),
                  label: const Text('Logo hochladen'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Salonname',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Address
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Phone
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Website
            TextField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Opening hours
            TextField(
              controller: _openingHoursController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Öffnungszeiten',
                border: OutlineInputBorder(),
                hintText: 'z.B. Mo–Sa 09:00–18:00',
              ),
            ),
            const SizedBox(height: 12),
            // Colour pickers
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickColour(primary: true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Primärfarbe'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickColour(primary: false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Akzentfarbe'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Block order header
            Text(
              'Layoutblöcke (ziehen zum Sortieren)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final block in _blocks)
                    ListTile(
                      key: ValueKey(block),
                      title: Text(block),
                      leading: const Icon(Icons.drag_handle),
                    ),
                ],
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final String item = _blocks.removeAt(oldIndex);
                    _blocks.insert(newIndex, item);
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Legal text toggle
            SwitchListTile(
              value: _useDefaultLegal,
              title: const Text('Standard-Rechtstexte verwenden'),
              onChanged: (value) {
                setState(() {
                  _useDefaultLegal = value;
                });
              },
            ),
            if (!_useDefaultLegal)
              TextField(
                controller: _legalTextController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Eigenes Impressum / DSGVO',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Speichern'),
              ),
            ),
            const SizedBox(height: 12),
            // Button to navigate to loyalty rules editor. Only visible to
            // salon owners or administrators.  Opens the loyalty rules
            // page where level thresholds and rewards can be configured.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/loyalty/rules');
                },
                child: const Text('Treue‑Regeln bearbeiten'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}