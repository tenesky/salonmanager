import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/themed_background.dart';

/// Onboarding screen for new customers.
///
/// After completing two‑factor authentication a normal user is guided
/// through a short personalisation flow. The user selects their
/// gender, preferred language, hair colour, hair length and hair
/// structure. Each selection is presented one at a time; after the
/// user makes a choice it is ticked off and the next question
/// automatically expands. Once all selections have been made the
/// "Finish" button becomes active and the preferences are stored
/// locally before navigating to the home page. The look and feel
/// follow the provided mockups: a dark patterned background with a
/// semi‑transparent overlay, rounded cards for each field and a
/// yellow progress bar at the top.
class OnboardingCustomerPage extends StatefulWidget {
  const OnboardingCustomerPage({Key? key}) : super(key: key);

  @override
  State<OnboardingCustomerPage> createState() => _OnboardingCustomerPageState();
}

class _OnboardingCustomerPageState extends State<OnboardingCustomerPage> {
  // Define selectable options for each field.
  final List<String> _genderOptions = const [
    'Männlich',
    'Weiblich',
    'Divers',
    'Keine Angabe',
  ];
  // A curated list of languages. In a full implementation this could
  // include all ISO languages. These serve as examples and can be
  // extended as needed.
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

  // Variables to hold the user’s selections.
  String? _selectedGender;
  String? _selectedLanguage;
  String? _selectedHairColor;
  String? _selectedHairLength;
  String? _selectedHairStructure;

  // Index of the currently expanded field (0–4). When a selection is
  // made, this index increments to show the next field. Once all
  // fields are completed it stays at 4. A value of -1 indicates
  // nothing is expanded (e.g. after selecting the last option).
  int _currentStep = 0;

  // Role indicates whether this onboarding is for a customer or
  // salon owner. Salon owners will proceed to another onboarding
  // screen after completing these personal questions. The default
  // role is `customer`. It is updated in didChangeDependencies
  // based on the route arguments.
  String _role = 'customer';

  /// Save the selected preferences to local storage. These values are
  /// stored under keys beginning with `onboarding.` so they can be
  /// retrieved later (e.g. in the profile page). In a full app this
  /// method might call a backend API to persist the data.
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding.gender', _selectedGender ?? '');
    await prefs.setString('onboarding.language', _selectedLanguage ?? '');
    await prefs.setString('onboarding.hairColor', _selectedHairColor ?? '');
    await prefs.setString('onboarding.hairLength', _selectedHairLength ?? '');
    await prefs.setString('onboarding.hairStructure', _selectedHairStructure ?? '');
  }

  /// Complete the onboarding: save preferences and navigate to the
  /// home page. The route `/home` must be registered in the app’s
  /// route table.
  Future<void> _finishOnboarding() async {
    await _savePreferences();
    if (!mounted) return;
    // If the role is salon, proceed to the salon onboarding page; otherwise
    // go straight to the home page. We replace the current page so
    // the user cannot navigate back to the onboarding.
    if (_role == 'salon') {
      Navigator.of(context).pushReplacementNamed('/onboarding-salon');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  /// Determine whether all fields have been selected. When this
  /// returns true the "Finish" button becomes enabled.
  bool get _isComplete =>
      _selectedGender != null &&
      _selectedLanguage != null &&
      _selectedHairColor != null &&
      _selectedHairLength != null &&
      _selectedHairStructure != null;

  /// Build a card representing one selection field. Depending on
  /// [index], this method uses the appropriate list of options and
  /// displays either a drop‑down selection (for the active step)
  /// or a disabled card with the selected value and a check icon.
  Widget _buildField({required int index, required String label}) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    // Map index to the correct data.
    List<String> options;
    String? selected;
    void Function(String?) onChanged;
    switch (index) {
      case 0:
        options = _genderOptions;
        selected = _selectedGender;
        onChanged = (value) {
          if (value == null) return;
          setState(() {
            _selectedGender = value;
            _currentStep = 1;
          });
        };
        break;
      case 1:
        options = _languageOptions;
        selected = _selectedLanguage;
        onChanged = (value) {
          if (value == null) return;
          setState(() {
            _selectedLanguage = value;
            _currentStep = 2;
          });
        };
        break;
      case 2:
        options = _hairColorOptions;
        selected = _selectedHairColor;
        onChanged = (value) {
          if (value == null) return;
          setState(() {
            _selectedHairColor = value;
            _currentStep = 3;
          });
        };
        break;
      case 3:
        options = _hairLengthOptions;
        selected = _selectedHairLength;
        onChanged = (value) {
          if (value == null) return;
          setState(() {
            _selectedHairLength = value;
            _currentStep = 4;
          });
        };
        break;
      case 4:
        options = _hairStructureOptions;
        selected = _selectedHairStructure;
        onChanged = (value) {
          if (value == null) return;
          setState(() {
            _selectedHairStructure = value;
            _currentStep = 4;
          });
        };
        break;
      default:
        options = const [];
        selected = null;
        onChanged = (_) {};
    }
    // Determine whether this field is currently active (expanded).
    final bool isActive = _currentStep == index;
    final bool isSelected = selected != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isActive
                  ? accent
                  : (brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black45),
              width: isActive ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display the selected value or the label.
              Text(
                isSelected ? '$label: $selected' : label,
                style: TextStyle(
                  color: brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Show a check icon when selected.
              if (isSelected)
                Icon(Icons.check_circle, color: accent)
              else
                // Show an arrow indicator if active, else nothing.
                (isActive
                    ? Icon(Icons.expand_more,
                        color: brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54)
                    : const SizedBox.shrink()),
            ],
          ),
        ),
        // If the field is active and not yet selected, show the options.
        if (isActive && !isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: options.map((option) {
                  final bool optionSelected = option == selected;
                  return ListTile(
                    title: Text(option,
                        style: TextStyle(
                          color: brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        )),
                    trailing: optionSelected
                        ? Icon(Icons.check, color: accent)
                        : null,
                    onTap: () => onChanged(option),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the role from route arguments once. If none is
    // provided, the default of `customer` applies.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final roleArg = args['role'];
      if (roleArg is String) {
        _role = roleArg;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    // Progress value based on completed steps. Each selection counts as
    // 1/5 of the bar. If all fields are done, the bar is full.
    double progress = 0.0;
    if (_selectedGender != null) progress += 0.2;
    if (_selectedLanguage != null) progress += 0.2;
    if (_selectedHairColor != null) progress += 0.2;
    if (_selectedHairLength != null) progress += 0.2;
    if (_selectedHairStructure != null) progress += 0.2;

    return Scaffold(
      // Use a transparent app bar with a back button. The back
      // navigation returns to the previous page (e.g. 2FA). If
      // necessary, adjust this behaviour for other flows.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ThemedBackground(
        child: Container(
          color: brightness == Brightness.dark
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.4),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6.0,
                      backgroundColor: brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Personalise your experience',
                    style: TextStyle(
                      color: brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your interests.',
                    style: TextStyle(
                      color: brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Build each field. Use labels in German for the field
                  // headers to match the provided example.
                  _buildField(index: 0, label: 'Geschlecht'),
                  const SizedBox(height: 16),
                  _buildField(index: 1, label: 'Sprache'),
                  const SizedBox(height: 16),
                  _buildField(index: 2, label: 'Haarfarbe'),
                  const SizedBox(height: 16),
                  _buildField(index: 3, label: 'Haarlänge'),
                  const SizedBox(height: 16),
                  _buildField(index: 4, label: 'Haarstruktur'),
                  const SizedBox(height: 32),
                  // Finish or Next button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isComplete ? _finishOnboarding : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Show "Next" when role is salon; otherwise "Finish".
                      child: Text(_role == 'salon' ? 'Next' : 'Finish'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}