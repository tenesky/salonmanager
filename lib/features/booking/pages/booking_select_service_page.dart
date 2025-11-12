import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/db_service.dart';

/// Second step of the booking wizard: select a service. This screen
/// presents the available services grouped into tabs for Damen,
/// Herren, Bart und Spezial. Each service is shown as a card with a
/// title, price range and duration. Tapping a card opens a bottom
/// sheet with a longer description and a button to select the
/// service. Without selecting a service the "Weiter" button stays
/// disabled. This corresponds to Screen 17 of the Wizard【522868310347694†L128-L136】.
class BookingSelectServicePage extends StatefulWidget {
  const BookingSelectServicePage({Key? key}) : super(key: key);

  @override
  State<BookingSelectServicePage> createState() => _BookingSelectServicePageState();
}

class _BookingSelectServicePageState extends State<BookingSelectServicePage>
    with SingleTickerProviderStateMixin {
  /// All services loaded from Supabase. Each map contains keys:
  /// `id` (int), `name` (String), `duration` (int minutes), `price`
  /// (num), `description` (String?), and `category` (String?).
  List<Map<String, dynamic>> _services = [];

  /// Services grouped by category for quick lookup. Keys are
  /// category names and values are lists of services.
  final Map<String, List<Map<String, dynamic>>> _servicesByCategory = {};

  /// Selected service IDs (as strings) for multi‑selection.
  Set<String> _selectedServiceIds = {};

  /// Categories for the TabBar. Even if a category has no services
  /// it will still appear to indicate that none are available.
  final List<String> _categories = ['Damen', 'Herren', 'Bart', 'Spezial'];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadDraftSelectedServices();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads previously selected service IDs from shared preferences. This
  /// ensures the user’s selections persist across sessions.
  Future<void> _loadDraftSelectedServices() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('draft_service_ids');
    if (ids != null) {
      setState(() {
        _selectedServiceIds = ids.toSet();
      });
    }
  }

  /// Persists the current selection of service IDs to shared
  /// preferences. Called whenever the selection changes.
  Future<void> _saveSelectedServices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('draft_service_ids', _selectedServiceIds.toList());
  }

  /// Loads available services from Supabase and groups them by
  /// category. Errors are ignored for now. The `category` field on
  /// the service record may be null; such services are placed into
  /// the "Spezial" category.
  Future<void> _loadServices() async {
    try {
      final services = await DbService.getServices();
      // Group services by category
      final Map<String, List<Map<String, dynamic>>> grouped = {
        for (final c in _categories) c: []
      };
      for (final s in services) {
        final String category = (s['category'] as String?) ?? 'Spezial';
        if (!grouped.containsKey(category)) {
          grouped[category] = [];
        }
        grouped[category]!.add(s);
      }
      setState(() {
        _services = services;
        _servicesByCategory
          ..clear()
          ..addAll(grouped);
      });
    } catch (_) {
      // In case of an error the lists remain empty.
    }
  }

  /// Toggles a service selection. If the service ID is already
  /// selected it will be removed, otherwise it is added. After
  /// updating the selection the new list is saved to shared
  /// preferences.
  Future<void> _toggleService(String id) async {
    setState(() {
      if (_selectedServiceIds.contains(id)) {
        _selectedServiceIds.remove(id);
      } else {
        _selectedServiceIds.add(id);
      }
    });
    await _saveSelectedServices();
  }

  /// Returns the list of services for the given tab index. Uses
  /// [_categories] and [_servicesByCategory].
  List<Map<String, dynamic>> _servicesForTab(int index) {
    final category = _categories[index];
    return _servicesByCategory[category] ?? [];
  }

  /// Calculates the total price (double) and total duration (minutes)
  /// of the currently selected services. The returned map has keys
  /// `price` and `duration`. If no services are selected, both
  /// values are zero.
  Map<String, num> _calculateTotals() {
    double priceSum = 0;
    int durationSum = 0;
    for (final id in _selectedServiceIds) {
      final svc = _services.firstWhere(
        (e) => e['id'].toString() == id,
        orElse: () => {},
      );
      if (svc.isNotEmpty) {
        final priceVal = svc['price'];
        if (priceVal is num) {
          priceSum += priceVal.toDouble();
        }
        final durationVal = svc['duration'];
        if (durationVal is int) {
          durationSum += durationVal;
        }
      }
    }
    return {'price': priceSum, 'duration': durationSum};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leistung wählen'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            tabs: _categories.map((c) => Tab(text: c)).toList(),
          ),
        ),
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
                    value: 2 / 8,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('2/8'),
              ],
            ),
          ),
          // Tab views containing service lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_categories.length, (index) {
                final services = _servicesForTab(index);
                if (services.isEmpty) {
                  return const Center(
                    child: Text('Keine Services verfügbar.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: services.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final service = services[i];
                    final bool isSelected = _selectedServiceIds.contains(service['id'].toString());
                    // Format price and duration for subtitle
                    String priceStr;
                    final priceVal = service['price'];
                    if (priceVal is num) {
                      priceStr = '€${priceVal.toStringAsFixed(2)}';
                    } else {
                      priceStr = priceVal?.toString() ?? '';
                    }
                    String durationStr;
                    final durVal = service['duration'];
                    if (durVal is int) {
                      durationStr = '${durVal} min';
                    } else {
                      durationStr = durVal?.toString() ?? '';
                    }
                    return Card(
                      child: ListTile(
                        title: Text(service['name']?.toString() ?? ''),
                        subtitle: Text('$priceStr • $durationStr'),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () {
                          _showServiceDetails(service);
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
      // Continue button. Enabled only if a service is selected.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary of selected services (price and duration)
            Builder(builder: (context) {
              final totals = _calculateTotals();
              final double price = totals['price'] as double;
              final int duration = totals['duration'] as int;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gesamt: €${price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('Dauer: ${duration} min',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selectedServiceIds.isNotEmpty
                  ? () {
                      Navigator.of(context).pushNamed('/booking/select-stylist');
                    }
                  : null,
              child: const Text('Weiter'),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays a bottom sheet with detailed information about the
  /// service. Includes a button to choose the service which stores
  /// the service ID and closes the sheet. This replicates the
  /// behavior described for the service cards【522868310347694†L128-L136】.
  void _showServiceDetails(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    service['name']?.toString() ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(service['description']?.toString() ?? ''),
              const SizedBox(height: 16),
              // Display formatted price and duration
              Builder(builder: (context) {
                final priceVal = service['price'];
                final priceStr = (priceVal is num)
                    ? '€${priceVal.toStringAsFixed(2)}'
                    : priceVal?.toString() ?? '';
                final durVal = service['duration'];
                final durationStr = (durVal is int)
                    ? '${durVal} min'
                    : durVal?.toString() ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preis: $priceStr'),
                    Text('Dauer: $durationStr'),
                  ],
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleService(service['id'].toString());
                  },
                  child: Text(_selectedServiceIds.contains(service['id'].toString())
                      ? 'Service abwählen'
                      : 'Service auswählen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}