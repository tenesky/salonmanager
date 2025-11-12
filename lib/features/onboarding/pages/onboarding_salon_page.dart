import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/themed_background.dart';

/// Onboarding screen for salon owners.
///
/// This page allows a new salon owner to customise their branding. The owner
/// can upload a logo, choose primary and accent colours and reorder layout
/// blocks. A live preview of the selected options is shown. When the user
/// completes the onboarding, the preferences are stored locally using
/// [SharedPreferences] and the app navigates to the home page. In a full
/// implementation, these values would be persisted to the backend.
class OnboardingSalonPage extends StatefulWidget {
  const OnboardingSalonPage({Key? key}) : super(key: key);

  @override
  State<OnboardingSalonPage> createState() => _OnboardingSalonPageState();
}

class _OnboardingSalonPageState extends State<OnboardingSalonPage> {
  Uint8List? _logoBytes;
  final ImagePicker _picker = ImagePicker();

  // Define a few colour options for primary and accent colours. The first entry
  // in each list is the default (Schwarz for primary and Gold for accent).
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

  @override
  void initState() {
    super.initState();
    _blockOrder = List<String>.from(_blockOptions);
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

  /// Persist the branding selections to local storage.
  Future<void> _saveBranding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboardingSalon.primaryColor', _primaryColor.value.toRadixString(16));
    await prefs.setString('onboardingSalon.accentColor', _accentColor.value.toRadixString(16));
    await prefs.setStringList('onboardingSalon.blockOrder', _blockOrder);
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
                'Lade dein Logo hoch, wähle Farben und ordne die Elemente deiner Salon‑Seite. Du siehst sofort eine Vorschau.',
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
                            color: _primaryColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
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
