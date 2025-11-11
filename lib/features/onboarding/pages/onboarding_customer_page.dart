import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/themed_background.dart';

/// Onboarding screen for new customers.
///
/// This page allows the user to select their hair length, preferred style
/// and hair color via chips. It also includes an opt‑in toggle for
/// marketing push notifications. When the user taps "Weiter", the
/// selections are persisted locally using [SharedPreferences] and the
/// customer is navigated to the home page.  In a real application
/// these values would also be sent to the backend via an API call.
class OnboardingCustomerPage extends StatefulWidget {
  const OnboardingCustomerPage({Key? key}) : super(key: key);

  @override
  State<OnboardingCustomerPage> createState() => _OnboardingCustomerPageState();
}

class _OnboardingCustomerPageState extends State<OnboardingCustomerPage> {
  // Lists of available options for each category.  These can be
  // customized or loaded from a remote source.  For the purposes of
  // this demo we provide a few sensible defaults.
  /// Hair length options with approximate lengths in centimetres.  These
  /// labels provide more context for users when selecting their
  /// preferred hair length. The underlying value stored is the full
  /// string (e.g. "Kurz (<10cm)") but could be normalised before
  /// sending to a backend if needed.
  final List<String> _hairLengthOptions =
      const ['Kurz (<10cm)', 'Mittel (10–20cm)', 'Lang (>20cm)'];
  final List<String> _styleOptions = const ['Klassisch', 'Modern', 'Trend'];
  final List<String> _colorOptions = const ['Blond', 'Braun', 'Schwarz', 'Rot'];

  String? _selectedHairLength;
  String? _selectedStyle;
  String? _selectedColor;
  bool _pushOptIn = false;

  /// Persists the current selections to local storage.  Uses the
  /// [SharedPreferences] plugin, which has been added to the project
  /// dependencies.  Each value is saved under its own key.
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding.hairLength', _selectedHairLength ?? '');
    await prefs.setString('onboarding.style', _selectedStyle ?? '');
    await prefs.setString('onboarding.color', _selectedColor ?? '');
    await prefs.setBool('onboarding.pushOptIn', _pushOptIn);
  }

  /// Navigates to the home page after saving preferences.  A loading
  /// indicator is shown while the preferences are being saved.
  Future<void> _completeOnboarding(BuildContext context) async {
    // Save the selections.
    await _savePreferences();
    if (!mounted) return;
    // Navigate to home.  Replace the current route so the onboarding
    // page is removed from the stack.
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
      // Use a themed background behind the content.  This provides
      // subtle texture and aligns with the global design guidelines.
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
              // Color selection
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
              // Optional skip button to allow users to bypass onboarding.
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
