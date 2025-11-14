import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/db_service.dart';

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
  /// List of stylists computed at runtime. Each map contains:
  /// `id` (string, either stylist id or 'auto'), `name`, `role`,
  /// `specialisations` (list of strings), `priceDiff` (double),
  /// `durationDiff` (int) and `isAuto` (bool).
  List<Map<String, dynamic>> _stylists = [];

  /// The currently selected stylist id (string). 'auto' represents
  /// automatic assignment.
  String _selectedStylistId = 'auto';

  @override
  void initState() {
    super.initState();
    _loadDraftStylistId();
    // Load stylists based on selected services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStylists());
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

  /// Loads stylists from Supabase based on selected services. It
  /// considers the list of service IDs stored under
  /// `draft_service_ids` to determine which stylists can perform
  /// all selected services. If no services are selected, all
  /// stylists are shown. Each stylist map in [_stylists] contains
  /// `id`, `name`, `role`, `specialisations`, `priceDiff`,
  /// `durationDiff` and `isAuto`.
  Future<void> _loadStylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? draftServiceStrings = prefs.getStringList('draft_service_ids');
      // Parse selected service IDs from strings to ints
      final List<int> selectedServices = draftServiceStrings
              ?.map((s) => int.tryParse(s) ?? -1)
              .where((id) => id > 0)
              .toList() ??
          [];
      // Fetch all stylists
      final stylistsData = await DbService.getStylists();
      // Fetch employee_service mappings
      final mappings = await DbService.getEmployeeServices();
      // Build a map from stylist_id to set of service_ids that are active
      final Map<int, Set<int>> stylistServices = {};
      for (final m in mappings) {
        final activeVal = m['active'];
        final bool isActive = activeVal is bool ? activeVal : false;
        if (!isActive) continue;
        final stylistId = m['stylist_id'];
        final serviceId = m['service_id'];
        if (stylistId is int && serviceId is int) {
          stylistServices.putIfAbsent(stylistId, () => <int>{});
          stylistServices[stylistId]!.add(serviceId);
        }
      }
      // Determine which stylist ids can perform all selected services
      Set<int> validStylistIds;
      if (selectedServices.isEmpty) {
        // All stylists are valid
        validStylistIds = stylistServices.keys.toSet();
      } else {
        validStylistIds = {};
        stylistServices.forEach((stylistId, services) {
          if (selectedServices.every((sid) => services.contains(sid))) {
            validStylistIds.add(stylistId);
          }
        });
      }
      // Fetch all services to compute names and base price/duration
      final servicesList = await DbService.getServices();
      final Map<int, Map<String, dynamic>> serviceById = {
        for (final svc in servicesList)
          if (svc['id'] is int) svc['id'] as int: svc
      };
      // Build the final stylist list. Include the auto option first.
      final List<Map<String, dynamic>> result = [];
      result.add({
        'id': 'auto',
        'name': 'Beliebig',
        'role': 'Automatisch',
        'specialisations': <String>[],
        'priceDiff': 0.0,
        'durationDiff': 0,
        'isAuto': true,
      });
      for (final stylist in stylistsData) {
        final stylistIdDynamic = stylist['id'];
        if (stylistIdDynamic is! int) continue;
        final int stylistId = stylistIdDynamic;
        // Only include valid stylists
        if (validStylistIds.isNotEmpty && !validStylistIds.contains(stylistId)) continue;
        final String name = stylist['name']?.toString() ?? '';
        // Determine role; no role column exists, default to 'Stylist'
        final String role = 'Stylist';
        // Determine specialisations: names of selected services
        final List<String> specs = [];
        for (final sid in selectedServices) {
          final svc = serviceById[sid];
          if (svc != null && svc['name'] != null) {
            specs.add(svc['name'].toString());
          }
        }
        // Compute price and duration differences (override minus base)
        double priceDiff = 0;
        int durationDiff = 0;
        for (final sid in selectedServices) {
          final baseSvc = serviceById[sid];
          final double basePrice = baseSvc != null && baseSvc['price'] is num
              ? (baseSvc['price'] as num).toDouble()
              : 0.0;
          final int baseDuration = baseSvc != null && baseSvc['duration'] is int
              ? baseSvc['duration'] as int
              : 0;
          // Find mapping for this stylist and service
          final mapping = mappings.firstWhere(
            (m) => m['stylist_id'] == stylistId && m['service_id'] == sid,
            orElse: () => {},
          );
          final overridePrice = mapping['price_override'];
          if (overridePrice is num) {
            priceDiff += overridePrice.toDouble() - basePrice;
          }
          final overrideDuration = mapping['duration_override'];
          if (overrideDuration is int) {
            durationDiff += overrideDuration - baseDuration;
          }
        }
        result.add({
          'id': stylistId.toString(),
          'name': name,
          'role': role,
          'specialisations': specs,
          'priceDiff': priceDiff,
          'durationDiff': durationDiff,
          'isAuto': false,
        });
      }
      setState(() {
        _stylists = result;
      });
    } catch (_) {
      // On error, fall back to auto assignment only
      setState(() {
        _stylists = [
          {
            'id': 'auto',
            'name': 'Beliebig',
            'role': 'Automatisch',
            'specialisations': <String>[],
            'priceDiff': 0.0,
            'durationDiff': 0,
            'isAuto': true,
          },
        ];
      });
    }
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
                final priceDiff = stylist['priceDiff'] as double? ?? 0.0;
                final durationDiff = stylist['durationDiff'] as int? ?? 0;
                // Format price and duration diff strings
                String? priceDiffStr;
                if (priceDiff.abs() > 0.01) {
                  final sign = priceDiff >= 0 ? '+' : '-';
                  priceDiffStr = '€$sign${priceDiff.abs().toStringAsFixed(2)}';
                }
                String? durationDiffStr;
                if (durationDiff != 0) {
                  final sign = durationDiff >= 0 ? '+' : '-';
                  durationDiffStr = '$sign${durationDiff.abs()} min';
                }
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
                            // Name
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
                            // Specialisations chips
                            if (!isAuto && (stylist['specialisations'] as List).isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final String spec in stylist['specialisations'] as List<String>)
                                    Chip(
                                      label: Text(spec),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                            // Price/duration diff
                            if (!isAuto && (priceDiffStr != null || durationDiffStr != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${priceDiffStr ?? ''}${priceDiffStr != null && durationDiffStr != null ? '  •  ' : ''}${durationDiffStr ?? ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const Spacer(),
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