import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/db_service.dart';

/// Allows users to view and update their personal preferences that were
/// collected during onboarding.  Preferences include gender, preferred
/// language, hair colour, hair length and hair structure.  The page
/// fetches existing values from the backend (via Supabase) on load and
/// updates both the local SharedPreferences and the remote record on save.
class UserPreferencesPage extends StatefulWidget {
  const UserPreferencesPage({Key? key}) : super(key: key);

  @override
  State<UserPreferencesPage> createState() => _UserPreferencesPageState();
}

class _UserPreferencesPageState extends State<UserPreferencesPage> {
  // Lists of options matching those used in the onboarding flow.
  final List<String> _genderOptions = const [
    'Männlich',
    'Weiblich',
    'Divers',
    'Keine Angabe',
  ];
  final List<String> _languageOptions = const [
    'Deutsch',
    'Englisch',
    'Französisch',
    'Spanisch',
    'Italienisch',
    'Türkisch',
    'Arabisch',
    'Russisch',
    'Chinesisch',
    'Japanisch',
  ];
  final List<String> _hairColorOptions = const [
    'Blond',
    'Braun',
    'Schwarz',
    'Rot',
    'Grau',
    'Weiß',
    'Bunt',
  ];
  final List<String> _hairLengthOptions = const [
    'Kurz (<10cm)',
    'Mittel (10–20cm)',
    'Lang (>20cm)',
  ];
  final List<String> _hairStructureOptions = const [
    'Glatt',
    'Wellig',
    'Lockig',
    'Kraus',
  ];

  // Currently selected values.  These are nullable until loaded.
  String? _gender;
  String? _language;
  String? _hairColor;
  String? _hairLength;
  String? _hairStructure;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Loads the existing preferences from Supabase.  If no preferences
  /// exist the selections remain null.  Local SharedPreferences are
  /// ignored on load because the backend is the source of truth.
  Future<void> _loadPreferences() async {
    try {
      final Map<String, dynamic>? prefs = await DbService.getUserPreferences();
      if (prefs != null) {
        setState(() {
          final dynamic g = prefs['gender'];
          if (g is String && g.isNotEmpty) _gender = g;
          final dynamic lang = prefs['language'];
          if (lang is String && lang.isNotEmpty) _language = lang;
          final dynamic hairC = prefs['hair_color'];
          if (hairC is String && hairC.isNotEmpty) _hairColor = hairC;
          final dynamic hairL = prefs['hair_length'];
          if (hairL is String && hairL.isNotEmpty) _hairLength = hairL;
          final dynamic hairS = prefs['hair_structure'];
          if (hairS is String && hairS.isNotEmpty) _hairStructure = hairS;
        });
      }
    } catch (_) {
      // Ignore errors; leave values as null.
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Saves the current selections to both local and remote storage.  The
  /// onboardingComplete flag is always set to true when updating from
  /// the profile, ensuring the user stays logged in without repeating
  /// the onboarding flow.
  Future<void> _savePreferences() async {
    if (_gender == null ||
        _language == null ||
        _hairColor == null ||
        _hairLength == null ||
        _hairStructure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder auswählen.')),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboarding.gender', _gender!);
      await prefs.setString('onboarding.language', _language!);
      await prefs.setString('onboarding.hairColor', _hairColor!);
      await prefs.setString('onboarding.hairLength', _hairLength!);
      await prefs.setString('onboarding.hairStructure', _hairStructure!);
      // Save remotely
      await DbService.upsertUserPreferences(
        gender: _gender!,
        language: _language!,
        hairColor: _hairColor!,
        hairLength: _hairLength!,
        hairStructure: _hairStructure!,
        onboardingComplete: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Einstellungen gespeichert.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    if (_loading) {
      return const Scaffold(
        appBar: AppBar(title: Text('Profil‑Einstellungen')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profil‑Einstellungen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdown(
              label: 'Geschlecht',
              value: _gender,
              options: _genderOptions,
              onChanged: (val) {
                setState(() {
                  _gender = val as String?;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Sprache',
              value: _language,
              options: _languageOptions,
              onChanged: (val) {
                setState(() {
                  _language = val as String?;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Haarfarbe',
              value: _hairColor,
              options: _hairColorOptions,
              onChanged: (val) {
                setState(() {
                  _hairColor = val as String?;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Haarlänge',
              value: _hairLength,
              options: _hairLengthOptions,
              onChanged: (val) {
                setState(() {
                  _hairLength = val as String?;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Haarstruktur',
              value: _hairStructure,
              options: _hairStructureOptions,
              onChanged: (val) {
                setState(() {
                  _hairStructure = val as String?;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _savePreferences,
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build a dropdown field with consistent styling.
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final brightness = Theme.of(context).brightness;
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: brightness == Brightness.dark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
          ),
        ),
      ),
      items: options
          .map((opt) => DropdownMenuItem<String>(
                value: opt,
                child: Text(opt),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}