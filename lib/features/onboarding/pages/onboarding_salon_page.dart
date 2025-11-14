import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/themed_background.dart';

/// Onboarding screen for salon owners.
///
/// This page allows a new salon owner to customise their branding and
/// salon details.  The owner can upload a logo, choose primary and
/// accent colours, specify the salon name and opening hours and decide
/// whether to use default legal texts or provide their own.  The
/// order of layout blocks can be adjusted and a live preview shows the
/// current selections.  When the user completes the onboarding, the
/// preferences are stored locally using [SharedPreferences] and the
/// app navigates to the home page. In a full implementation, these
/// values would also be persisted to Supabase.
class OnboardingSalonPage extends StatefulWidget {
  const OnboardingSalonPage({Key? key}) : super(key: key);

  @override
  State<OnboardingSalonPage> createState() => _OnboardingSalonPageState();
}

class _OnboardingSalonPageState extends State<OnboardingSalonPage> {
  Uint8List? _logoBytes;
  final ImagePicker _picker = ImagePicker();

  // Colour options for primary and accent colours.  The first entry is
  // the default (Schwarz for primary and Gold for accent).
  final List<Color> _primaryOptions = [
    const Color(0xFF000000), // Schwarz
    const Color(0xFF212121),
    const Color(0xFF424242),
  ];
  final List<String> _primaryNames = [
    'Schwarz',
    'Dunkelgrau',
    'Mittelgrau',
  ];
  final List<Color> _accentOptions = [
    const Color(0xFFFFD700), // Gold
    const Color(0xFFCD7F32), // Bronze
    const Color(0xFFC0C0C0), // Silber
    Colors.deepOrange,
  ];
  final List<String> _accentNames = [
    'Gold',
    'Bronze',
    'Silber',
    'Orange',
  ];

  Color _primaryColor = const Color(0xFF000000);
  Color _accentColor = const Color(0xFFFFD700);

  final List<String> _blockOptions = const ['Hero', 'Services', 'Team', 'Gallery'];
  late List<String> _blockOrder;

  // Controllers for additional salon details.
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  final TextEditingController _legalTextController = TextEditingController();
  bool _useDefaultLegalText = true;

  @override
  void initState() {
    super.initState();
    _blockOrder = List<String>.from(_blockOptions);
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _openingHoursController.dispose();
    _legalTextController.dispose();
    super.dispose();
  }

  /// Pick an image from the device gallery for the logo. The selected
  /// image is stored as bytes in memory and shown in the preview.
  Future<void> _pickLogo() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _logoBytes = bytes;
      });
    }
  }

  /// Persist the branding and salon details to local storage.  Each
  /// value is saved under its own key.  The colour values are saved
  /// as hexadecimal strings.  If a logo was uploaded its bytes are
  /// base64‑encoded.
  Future<void> _saveBranding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboardingSalon.primaryColor', _primaryColor.value.toRadixString(16));
    await prefs.setString('onboardingSalon.accentColor', _accentColor.value.toRadixString(16));
    await prefs.setStringList('onboardingSalon.blockOrder', _blockOrder);
    await prefs.setString('onboardingSalon.salonName', _salonNameController.text.trim());
    await prefs.setString('onboardingSalon.openingHours', _openingHoursController.text.trim());
    await prefs.setBool('onboardingSalon.useDefaultLegalText', _useDefaultLegalText);
    await prefs.setString('onboardingSalon.legalText', _legalTextController.text.trim());
    if (_logoBytes != null) {
      final encoded = base64Encode(_logoBytes!);
      await prefs.setString('onboardingSalon.logo', encoded);
    }
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    await _saveBranding();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon‑Branding einrichten'),
        automaticallyImplyLeading: false,
      ),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gestalte deinen Salon',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Lade dein Logo hoch, wähle Farben und ordne die Elemente deiner Salon‑Seite. Du kannst auch den Namen, Öffnungszeiten und Rechtstexte anpassen. Eine Vorschau zeigt dir sofort das Ergebnis.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              // Logo section
              Text('Logo', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo preview
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8.0),
                      image: _logoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_logoBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _logoBytes == null
                        ? Icon(Icons.image, color: theme.colorScheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.upload),
                      label: const Text('Logo hochladen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Primary colour selection
              Text('Primärfarbe', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: List<Widget>.generate(_primaryOptions.length, (index) {
                  final color = _primaryOptions[index];
                  final name = _primaryNames[index];
                  final selected = _primaryColor == color;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(name),
                      ],
                    ),
                    selected: selected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _primaryColor = color;
                        });
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Accent colour selection
              Text('Akzentfarbe', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: List<Widget>.generate(_accentOptions.length, (index) {
                  final color = _accentOptions[index];
                  final name = _accentNames[index];
                  final selected = _accentColor == color;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(name),
                      ],
                    ),
                    selected: selected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _accentColor = color;
                        });
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Salon details section
              Text('Salon‑Details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _salonNameController,
                decoration: const InputDecoration(
                  labelText: 'Salon‑Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _openingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Öffnungszeiten',
                  hintText: 'z.B. Mo–Sa 09:00–18:00',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Standard‑Rechtstexte verwenden'),
                subtitle: const Text('Wenn deaktiviert, kannst du eigene Texte eingeben.'),
                value: _useDefaultLegalText,
                onChanged: (val) {
                  setState(() {
                    _useDefaultLegalText = val;
                    if (val) {
                      _legalTextController.clear();
                    }
                  });
                },
              ),
              if (!_useDefaultLegalText)
                TextField(
                  controller: _legalTextController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Eigene Rechtstexte',
                    hintText: 'Impressum, AGB, Datenschutz …',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (!_useDefaultLegalText) const SizedBox(height: 24),
              // Layout order section
              Text('Layout‑Blöcke (Reihenfolge ändern)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _blockOrder.removeAt(oldIndex);
                      _blockOrder.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (final block in _blockOrder)
                      ListTile(
                        key: ValueKey(block),
                        title: Text(block),
                        leading: const Icon(Icons.drag_handle),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Live preview section
              Text('Live‑Vorschau', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_logoBytes != null)
                      Container(
                        height: 60,
                        alignment: Alignment.centerLeft,
                        child: Image.memory(_logoBytes!, height: 50),
                      ),
                    if (_salonNameController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          _salonNameController.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    if (_openingHoursController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          _openingHoursController.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    for (final block in _blockOrder)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        height: 32,
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          block,
                          style: TextStyle(
                            color: _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (!_useDefaultLegalText && _legalTextController.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          _legalTextController.text.trim().length > 60
                              ? _legalTextController.text.trim().substring(0, 60) + '…'
                              : _legalTextController.text.trim(),
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    else if (_useDefaultLegalText)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'Standard‑Rechtstexte werden verwendet',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeOnboarding(context),
                  child: const Text('Weiter'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                child: const Text('Überspringen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
