import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Third step of the booking wizard: select a stylist.  
///
/// This screen displays a grid of available stylists for the chosen
/// service. Each tile shows the stylist’s profile picture, role and
/// specialisations as chips. The first tile represents an
/// “Automatisch zuweisen” option which is preselected by default and
/// instructs the system to assign any available stylist.  
/// Selecting a stylist stores the `stylist_id` (or `auto` for the
/// auto assignment) in local storage so that the draft persists
/// across sessions. A progress indicator shows that the user is on
/// step 3 of 8.  
/// This page corresponds to Screen 18 in the specification【522868310347694†L142-L149】.
class BookingSelectStylistPage extends StatefulWidget {
  const BookingSelectStylistPage({Key? key}) : super(key: key);

  @override
  State<BookingSelectStylistPage> createState() => _BookingSelectStylistPageState();
}

class _BookingSelectStylistPageState extends State<BookingSelectStylistPage> {
  /// List of stylists available for demonstration. Each map contains
  /// identifiers and display information. In a real application this
  /// data would be fetched from the backend based on the selected
  /// salon and service【522868310347694†L142-L147】.
  final List<Map<String, dynamic>> _stylists = [
    {
      'id': 'auto',
      'name': 'Automatisch zuweisen',
      'role': 'Standard',
      'specialisations': <String>[],
      'price': null,
      'duration': null,
      'isAuto': true,
    },
    {
      'id': 's1',
      'name': 'Lena Müller',
      'role': 'Master Stylistin',
      'specialisations': ['Color', 'Balayage'],
      'price': '€+10',
      'duration': '+10 min',
      'isAuto': false,
    },
    {
      'id': 's2',
      'name': 'Maximilian Schröder',
      'role': 'Stylist',
      'specialisations': ['Herren', 'Bart'],
      'price': null,
      'duration': null,
      'isAuto': false,
    },
    {
      'id': 's3',
      'name': 'Aylin Kaya',
      'role': 'Senior Stylistin',
      'specialisations': ['Damen', 'Updo', 'Färben'],
      'price': '€+15',
      'duration': '+15 min',
      'isAuto': false,
    },
  ];

  String _selectedStylistId = 'auto';

  @override
  void initState() {
    super.initState();
    _loadDraftStylistId();
  }

  /// Loads a previously selected stylist ID from shared preferences.  
  /// Defaults to the auto assignment if none is found.
  Future<void> _loadDraftStylistId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('draft_stylist_id');
    setState(() {
      _selectedStylistId = stored ?? 'auto';
    });
  }

  /// Persists the selected stylist ID to shared preferences and updates
  /// the local state. When the "Automatisch zuweisen" tile is
  /// selected the id will be `auto` to indicate auto assignment.
  Future<void> _selectStylist(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_stylist_id', id);
    setState(() {
      _selectedStylistId = id;
    });
    // Provide immediate user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(id == 'auto' ? 'Automatische Zuweisung gewählt' : 'Stylist ausgewählt')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stylist wählen'),
      ),
      body: Column(
        children: [
          // Progress indicator and step label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 3 / 8,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('3/8'),
              ],
            ),
          ),
          // Grid of stylists
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3 / 4,
              ),
              itemCount: _stylists.length,
              itemBuilder: (context, index) {
                final stylist = _stylists[index];
                final bool isSelected = stylist['id'] == _selectedStylistId;
                final bool isAuto = stylist['isAuto'] as bool;
                return Tooltip(
                  message: isAuto
                      ? 'Wir wählen automatisch den passenden Stylisten basierend auf Verfügbarkeit.'
                      : '',
                  child: GestureDetector(
                    onTap: () => _selectStylist(stylist['id'] as String),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                            : BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile picture or icon
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              child: isAuto
                                  ? const Icon(Icons.shuffle, size: 32)
                                  : const Icon(Icons.person, size: 32),
                            ),
                            const SizedBox(height: 8),
                            // Name / title
                            Text(
                              stylist['name'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            // Role
                            if (!isAuto)
                              Text(
                                stylist['role'] as String,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 6),
                            // Specialisations as chips
                            if (!isAuto)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final spec in stylist['specialisations'] as List<String>)
                                    Chip(
                                      label: Text(spec),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                            // Price and duration override
                            if (!isAuto && (stylist['price'] != null || stylist['duration'] != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${stylist['price'] ?? ''}${stylist['price'] != null && stylist['duration'] != null ? '  •  ' : ''}${stylist['duration'] ?? ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const Spacer(),
                            // Selection indicator
                            if (isSelected)
                              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                            else
                              const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // The stylist selection is optional. The auto assignment is
            // preselected by default so the continue button is always
            // enabled.
            Navigator.of(context).pushNamed('/booking/select-date');
          },
          child: const Text('Weiter'),
        ),
      ),
    );
  }
}