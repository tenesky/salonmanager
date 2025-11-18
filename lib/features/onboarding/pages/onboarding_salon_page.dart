import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// We import DbService from the services folder to create and update
// salon records. The relative path requires three segments up because
// this file resides in lib/features/onboarding/pages.
import '../../../services/db_service.dart';

import '../../../common/themed_background.dart';

/// Onboarding screen for new salon owners.
///
/// This page guides salon owners through a multi‑step process to
/// capture essential business details: the salon name, address,
/// contact information and opening hours. Each section expands
/// sequentially—once a section is completed it is marked with a
/// check icon and the next section automatically becomes active.
/// A progress bar at the top visualises completion. When all
/// sections are finished the "Finish" button becomes enabled and
/// the collected data is saved locally before navigating to the
/// home page. Data persistence uses SharedPreferences; in a real
/// implementation these values would also be sent to a backend.
class OnboardingSalonPage extends StatefulWidget {
  const OnboardingSalonPage({Key? key}) : super(key: key);

  @override
  State<OnboardingSalonPage> createState() => _OnboardingSalonPageState();
}

class _OnboardingSalonPageState extends State<OnboardingSalonPage> {
  // Controllers for the main salon fields.
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _email1Controller = TextEditingController();
  final TextEditingController _email2Controller = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();

  // Opening hours configuration: list of day names and corresponding
  // controllers for start and end times. A boolean indicates if the
  // salon is closed on that day. The last entry represents
  // holidays (Feiertage).
  final List<String> _days = const [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
    'Feiertage',
  ];
  late final List<bool> _openingIsClosed;
  late final List<TextEditingController> _openingStartControllers;
  late final List<TextEditingController> _openingEndControllers;
  // Keys for storing opening hours in SharedPreferences. Use simple
  // lowercase abbreviations to avoid special characters.
  final List<String> _dayKeys = const [
    'mo', 'di', 'mi', 'do', 'fr', 'sa', 'so', 'holidays'
  ];

  // State flags indicating whether a section has been completed.
  bool _isSalonNameDone = false;
  bool _isAddressDone = false;
  bool _isContactDone = false;
  bool _isOpeningDone = false;

  // Helper to compute the current step based on completed flags. The
  // first incomplete section becomes active.
  int get _currentStep {
    if (!_isSalonNameDone) return 0;
    if (!_isAddressDone) return 1;
    if (!_isContactDone) return 2;
    if (!_isOpeningDone) return 3;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    _openingIsClosed = List<bool>.filled(_days.length, false);
    _openingStartControllers =
        List<TextEditingController>.generate(_days.length, (_) => TextEditingController());
    _openingEndControllers =
        List<TextEditingController>.generate(_days.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    // Dispose all controllers to free resources.
    _salonNameController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _email1Controller.dispose();
    _email2Controller.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    for (final c in _openingStartControllers) {
      c.dispose();
    }
    for (final c in _openingEndControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Persist all collected data to SharedPreferences. Keys are
  /// namespaced under `onboardingSalon`. In a full app this data
  /// would also be sent to a server.
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboardingSalon.name', _salonNameController.text.trim());
    await prefs.setString('onboardingSalon.address.street', _streetController.text.trim());
    await prefs.setString('onboardingSalon.address.number', _houseNumberController.text.trim());
    await prefs.setString('onboardingSalon.address.postalCode', _postalCodeController.text.trim());
    await prefs.setString('onboardingSalon.address.city', _cityController.text.trim());
    await prefs.setString('onboardingSalon.address.country', _countryController.text.trim());
    await prefs.setString('onboardingSalon.contact.email1', _email1Controller.text.trim());
    await prefs.setString('onboardingSalon.contact.email2', _email2Controller.text.trim());
    await prefs.setString('onboardingSalon.contact.phone1', _phone1Controller.text.trim());
    await prefs.setString('onboardingSalon.contact.phone2', _phone2Controller.text.trim());
    // Save opening hours for each day.
    for (int i = 0; i < _days.length; i++) {
      await prefs.setBool(
          'onboardingSalon.openingHours.${_dayKeys[i]}.closed', _openingIsClosed[i]);
      await prefs.setString(
          'onboardingSalon.openingHours.${_dayKeys[i]}.start',
          _openingStartControllers[i].text.trim());
      await prefs.setString(
          'onboardingSalon.openingHours.${_dayKeys[i]}.end',
          _openingEndControllers[i].text.trim());
    }
  }

  /// Completes the onboarding by saving preferences and navigating
  /// to the home page.
  Future<void> _finishOnboarding() async {
    // Save the collected preferences locally
    await _savePreferences();
    // Also create the salon in the database so it appears in lists and on the map.
    try {
      // Obtain the current user id from Supabase Auth. If the user is not
      // authenticated for some reason, ownerId will be null and the
      // following call may throw. In that case we silently ignore the
      // database insertion.
      final ownerId = Supabase.instance.client.auth.currentUser?.id;
      if (ownerId != null && _salonNameController.text.trim().isNotEmpty) {
        // Build a combined address string from the provided fields. If any
        // components are empty they are omitted.
        final parts = <String>[];
        if (_streetController.text.trim().isNotEmpty) {
          final street = _streetController.text.trim();
          if (_houseNumberController.text.trim().isNotEmpty) {
            parts.add('$street ${_houseNumberController.text.trim()}');
          } else {
            parts.add(street);
          }
        }
        if (_postalCodeController.text.trim().isNotEmpty ||
            _cityController.text.trim().isNotEmpty) {
          final postal = _postalCodeController.text.trim();
          final city = _cityController.text.trim();
          if (postal.isNotEmpty && city.isNotEmpty) {
            parts.add('$postal $city');
          } else {
            parts.add(postal + city);
          }
        }
        if (_countryController.text.trim().isNotEmpty) {
          parts.add(_countryController.text.trim());
        }
        final combinedAddress = parts.join(', ');
        // Insert the salon and get its id
        final salonId = await DbService.addSalon(
          ownerId: ownerId,
          name: _salonNameController.text.trim(),
          address: combinedAddress.isNotEmpty ? combinedAddress : null,
        );
        // Prepare phone number: use the first provided phone entry if any
        String? phone;
        if (_phone1Controller.text.trim().isNotEmpty) {
          phone = _phone1Controller.text.trim();
        } else if (_phone2Controller.text.trim().isNotEmpty) {
          phone = _phone2Controller.text.trim();
        }
        // Build opening hours string. Format each line as "Tag: start‑end" or
        // "Tag: geschlossen" for closed days. Combine with newlines.
        final openingLines = <String>[];
        for (int i = 0; i < _days.length; i++) {
          final day = _days[i];
          if (_openingIsClosed[i]) {
            openingLines.add('$day: geschlossen');
          } else {
            final start = _openingStartControllers[i].text.trim();
            final end = _openingEndControllers[i].text.trim();
            if (start.isNotEmpty && end.isNotEmpty) {
              openingLines.add('$day: $start-$end');
            } else {
              // If times are missing, mark as geschlossen
              openingLines.add('$day: geschlossen');
            }
          }
        }
        final openingHours = openingLines.join('\n');
        // Update additional salon details
        await DbService.updateSalonProfile(
          salonId: salonId,
          phone: phone,
          openingHours: openingHours,
        );
        // Mark the user onboarding as complete. This will allow skipping the
        // onboarding flow when logging in again. We ignore any errors
        // encountered here so the navigation continues.
        try {
          await DbService.markOnboardingComplete();
        } catch (_) {}
      }
    } catch (_) {
      // Ignore errors during salon creation; the onboarding will still
      // complete and the user can add the salon later via profile settings.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  /// Validates that the salon name has been entered. Returns true if
  /// non‑empty.
  bool _validateSalonName() {
    return _salonNameController.text.trim().isNotEmpty;
  }

  /// Completes the salon name step if valid. Shows an error if the
  /// field is empty.
  void _completeSalonName() {
    if (_validateSalonName()) {
      setState(() {
        _isSalonNameDone = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte den Salon‑Namen eingeben.')),
      );
    }
  }

  /// Validates that all address fields (except possibly country) are
  /// non‑empty. Returns true if valid. You may adjust the validation
  /// rules here (e.g. make the country optional or required).
  bool _validateAddress() {
    return _streetController.text.trim().isNotEmpty &&
        _houseNumberController.text.trim().isNotEmpty &&
        _postalCodeController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _countryController.text.trim().isNotEmpty;
  }

  /// Completes the address step if valid. Shows an error if any
  /// required field is missing.
  void _completeAddress() {
    if (_validateAddress()) {
      setState(() {
        _isAddressDone = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Adressfelder ausfüllen.')),
      );
    }
  }

  /// Validates contact details. At least one email and one phone
  /// number must be provided and valid. A simple regex is used for
  /// email addresses; phone numbers may include digits, spaces,
  /// dashes or a leading plus. Returns true if valid.
  bool _validateContact() {
    final emailRegex = RegExp(r'^([^@\s]+)@([^@\s]+)\.[^@\s]+$');
    bool validEmail1 = _email1Controller.text.trim().isNotEmpty &&
        emailRegex.hasMatch(_email1Controller.text.trim());
    bool validEmail2 = _email2Controller.text.trim().isNotEmpty &&
        emailRegex.hasMatch(_email2Controller.text.trim());
    final phoneRegex = RegExp(r'^\+?[0-9\s\-]{5,}\$');
    bool validPhone1 = _phone1Controller.text.trim().isNotEmpty &&
        phoneRegex.hasMatch(_phone1Controller.text.trim());
    bool validPhone2 = _phone2Controller.text.trim().isNotEmpty &&
        phoneRegex.hasMatch(_phone2Controller.text.trim());
    return (validEmail1 || validEmail2) && (validPhone1 || validPhone2);
  }

  /// Completes the contact step if valid. Shows an error if the
  /// validation fails.
  void _completeContact() {
    if (_validateContact()) {
      setState(() {
        _isContactDone = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte mindestens eine gültige E‑Mail und eine Telefonnummer angeben.')),
      );
    }
  }

  /// Validates the opening hours. For each day (including
  /// holidays), either the day is marked as closed or both start
  /// and end times are provided. Returns true if all entries meet
  /// these conditions.
  bool _validateOpeningHours() {
    for (int i = 0; i < _days.length; i++) {
      if (!_openingIsClosed[i]) {
        if (_openingStartControllers[i].text.trim().isEmpty ||
            _openingEndControllers[i].text.trim().isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  /// Completes the opening hours step if valid. Shows an error if
  /// any day lacks the required information.
  void _completeOpening() {
    if (_validateOpeningHours()) {
      setState(() {
        _isOpeningDone = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte für jeden Tag Öffnungszeiten angeben oder als geschlossen markieren.')),
      );
    }
  }

  /// Build the salon name field. Shows the selected value and a check
  /// when completed; otherwise presents a text field and save button.
  Widget _buildSalonNameField(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    final bool isDone = _isSalonNameDone;
    final bool isActive = (_currentStep == 0);
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
              Flexible(
                child: Text(
                  isDone
                      ? 'Salonname: ${_salonNameController.text.trim()}'
                      : 'Salonname',
                  style: TextStyle(
                    color: brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isDone)
                Icon(Icons.check_circle, color: accent)
              else if (isActive)
                Icon(Icons.expand_more,
                    color: brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        if (isActive && !isDone)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _salonNameController,
                  // Trigger a rebuild when the user edits the salon name so the
                  // save button can be enabled or disabled accordingly.
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Salonname',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _salonNameController.text.trim().isNotEmpty
                        ? _completeSalonName
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Speichern und weiter'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build the address field. Shows the entered address when completed.
  Widget _buildAddressField(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    final bool isDone = _isAddressDone;
    final bool isActive = (_currentStep == 1);
    // Concatenate address for display when done.
    final String addressDisplay =
        '${_streetController.text.trim()} ${_houseNumberController.text.trim()}, ${_postalCodeController.text.trim()} ${_cityController.text.trim()}, ${_countryController.text.trim()}';
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
              Expanded(
                child: Text(
                  isDone ? 'Adresse: $addressDisplay' : 'Adresse',
                  style: TextStyle(
                    color: brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDone)
                Icon(Icons.check_circle, color: accent)
              else if (isActive)
                Icon(Icons.expand_more,
                    color: brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        if (isActive && !isDone)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _streetController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Straße',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _houseNumberController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Hausnummer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _postalCodeController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'PLZ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cityController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Ort',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _countryController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Land',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _validateAddress() ? _completeAddress : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Speichern und weiter'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build the contact field. Shows selected emails and phones when
  /// completed; otherwise displays input fields.
  Widget _buildContactField(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    final bool isDone = _isContactDone;
    final bool isActive = (_currentStep == 2);
    String contactDisplay = '';
    if (_isContactDone) {
      List<String> emails = [];
      if (_email1Controller.text.trim().isNotEmpty) emails.add(_email1Controller.text.trim());
      if (_email2Controller.text.trim().isNotEmpty) emails.add(_email2Controller.text.trim());
      List<String> phones = [];
      if (_phone1Controller.text.trim().isNotEmpty) phones.add(_phone1Controller.text.trim());
      if (_phone2Controller.text.trim().isNotEmpty) phones.add(_phone2Controller.text.trim());
      contactDisplay = 'E-Mail: ${emails.join(', ')} / Tel: ${phones.join(', ')}';
    }
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
              Expanded(
                child: Text(
                  isDone ? 'Kontaktdaten: $contactDisplay' : 'Kontaktdaten',
                  style: TextStyle(
                    color: brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDone)
                Icon(Icons.check_circle, color: accent)
              else if (isActive)
                Icon(Icons.expand_more,
                    color: brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        if (isActive && !isDone)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _email1Controller,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'E-Mail Adresse 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _email2Controller,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'E-Mail Adresse 2 (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone1Controller,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Telefonnummer 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone2Controller,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Telefonnummer 2 (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _validateContact() ? _completeContact : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Speichern und weiter'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build the opening hours field. Lists each day with a toggle and
  /// time inputs. Holidays are included as the last entry.
  Widget _buildOpeningField(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    final bool isDone = _isOpeningDone;
    final bool isActive = (_currentStep == 3);
    // Display summary of opening hours when done. We summarise
    // closed days and show first day times as an example. You could
    // expand this to a more detailed summary if desired.
    String openingDisplay = '';
    if (isDone) {
      List<String> parts = [];
      for (int i = 0; i < _days.length; i++) {
        if (_openingIsClosed[i]) {
          parts.add('${_days[i]}: geschlossen');
        } else {
          final start = _openingStartControllers[i].text.trim();
          final end = _openingEndControllers[i].text.trim();
          parts.add('${_days[i]}: $start–$end');
        }
      }
      openingDisplay = parts.join(' | ');
    }
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
              Expanded(
                child: Text(
                  isDone ? 'Öffnungszeiten: $openingDisplay' : 'Öffnungszeiten',
                  style: TextStyle(
                    color: brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDone)
                Icon(Icons.check_circle, color: accent)
              else if (isActive)
                Icon(Icons.expand_more,
                    color: brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        if (isActive && !isDone)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Generate fields for each day. Each day shows a
                // label, a toggle for closed, and optional start/end
                // time fields. Spacing is handled between entries.
                for (int i = 0; i < _days.length; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _days[i],
                        style: TextStyle(
                          color: brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      Switch(
                        value: !_openingIsClosed[i],
                        activeColor: accent,
                        onChanged: (bool val) {
                          setState(() {
                            _openingIsClosed[i] = !val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (!_openingIsClosed[i])
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _openingStartControllers[i],
                            keyboardType: TextInputType.datetime,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Von (HH:MM)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _openingEndControllers[i],
                            keyboardType: TextInputType.datetime,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Bis (HH:MM)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _validateOpeningHours() ? _completeOpening : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Speichern und weiter'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    // Compute progress: each completed section contributes 0.25.
    double progress = 0.0;
    if (_isSalonNameDone) progress += 0.25;
    if (_isAddressDone) progress += 0.25;
    if (_isContactDone) progress += 0.25;
    if (_isOpeningDone) progress += 0.25;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: brightness == Brightness.dark ? Colors.white : Colors.black),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Personalise your Salon',
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
                    'Gib deine Salon‑Details ein.',
                    style: TextStyle(
                      color: brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSalonNameField(context),
                  const SizedBox(height: 16),
                  _buildAddressField(context),
                  const SizedBox(height: 16),
                  _buildContactField(context),
                  const SizedBox(height: 16),
                  _buildOpeningField(context),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isOpeningDone ? _finishOnboarding : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Finish'),
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