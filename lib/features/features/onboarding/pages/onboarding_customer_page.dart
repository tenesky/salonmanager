import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/themed_background.dart';

/// Onboarding screen for new customers.
///
/// This page allows a user to customise basic preferences such as hair
/// length, style and colour, and to provide contact details.  The
/// selections are stored locally via SharedPreferences and can be used
/// later for personalisation.  A "Weiter" button completes the
/// onboarding and navigates to the home page.
class OnboardingCustomerPage extends StatefulWidget {
  const OnboardingCustomerPage({Key? key}) : super(key: key);

  @override
  State<OnboardingCustomerPage> createState() => _OnboardingCustomerPageState();
}

class _OnboardingCustomerPageState extends State<OnboardingCustomerPage> {
  final List<String> _hairLengthOptions =
      const ['Kurz (<10cm)', 'Mittel (10–20cm)', 'Lang (>20cm)'];
  final List<String> _styleOptions = const ['Klassisch', 'Modern', 'Trend'];
  final List<String> _colorOptions = const ['Blond', 'Braun', 'Schwarz', 'Rot'];

  String? _selectedHairLength;
  String? _selectedStyle;
  String? _selectedColor;
  bool _pushOptIn = false;

  // Contact information controllers.  The phone number helps with
  // appointment reminders; the address is optional and can be used
  // later for location‑based suggestions.
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Persist the selections and contact information to local storage.
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding.hairLength', _selectedHairLength ?? '');
    await prefs.setString('onboarding.style', _selectedStyle ?? '');
    await prefs.setString('onboarding.color', _selectedColor ?? '');
    await prefs.setBool('onboarding.pushOptIn', _pushOptIn);
    await prefs.setString('onboarding.phone', _phoneController.text.trim());
    await prefs.setString('onboarding.address', _addressController.text.trim());
  }

  /// Save preferences and navigate to the home page.
  Future<void> _completeOnboarding(BuildContext context) async {
    await _savePreferences();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erst‑Onboarding'),
        automaticallyImplyLeading: false,
      ),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Erzähl uns mehr über dich',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Wähle deine bevorzugte Haarlänge, deinen Stil und deine Lieblingsfarbe. Dies hilft uns, bessere Vorschläge zu machen.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              // Hair length selection
              Text('Haarlänge', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _hairLengthOptions.map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: _selectedHairLength == option,
                    onSelected: (selected) {
                      setState(() {
                        _selectedHairLength = selected ? option : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Style selection
              Text('Stil', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _styleOptions.map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: _selectedStyle == option,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStyle = selected ? option : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Colour selection
              Text('Farbe', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _colorOptions.map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: _selectedColor == option,
                    onSelected: (selected) {
                      setState(() {
                        _selectedColor = selected ? option : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Contact fields
              Text('Kontakt', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefonnummer',
                  hintText: '+49 123 4567890',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optional)',
                  hintText: 'Straße, PLZ, Ort',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              // Push marketing opt‑in
              SwitchListTile(
                title: const Text('Ich möchte Marketing‑Push‑Benachrichtigungen erhalten'),
                subtitle: const Text('Du kannst diese Einstellung später ändern.'),
                value: _pushOptIn,
                activeColor: theme.colorScheme.secondary,
                onChanged: (value) {
                  setState(() {
                    _pushOptIn = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedHairLength != null &&
                          _selectedStyle != null &&
                          _selectedColor != null)
                      ? () => _completeOnboarding(context)
                      : null,
                  child: const Text('Weiter'),
                ),
              ),
              const SizedBox(height: 16),
              // Optional skip button
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                ),
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
