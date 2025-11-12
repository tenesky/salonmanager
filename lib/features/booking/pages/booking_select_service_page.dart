import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Sample data for services. Each entry has an id, title, price
  // range, duration, detailed description and the category it
  // belongs to. In a real app this would be fetched from the backend
  // based on the selected salon.
  final List<Map<String, String>> _services = [
    {
      'id': 'd1',
      'category': 'Damen',
      'title': 'Damenhaarschnitt',
      'price': '€40–€60',
      'duration': '60 min',
      'description':
          'Ein klassischer Damenhaarschnitt inklusive Waschen, Schneiden und Styling. Geeignet für alle Haarlängen.',
    },
    {
      'id': 'd2',
      'category': 'Damen',
      'title': 'Färben & Strähnen',
      'price': '€70–€120',
      'duration': '90 min',
      'description':
          'Farbbehandlung mit individueller Beratung. Inklusive Pflegespülung und Styling.',
    },
    {
      'id': 'h1',
      'category': 'Herren',
      'title': 'Herrenhaarschnitt',
      'price': '€25–€40',
      'duration': '30 min',
      'description': 'Modischer Herrenhaarschnitt inklusive Waschen und Styling.',
    },
    {
      'id': 'h2',
      'category': 'Herren',
      'title': 'Rasur & Bartpflege',
      'price': '€20–€35',
      'duration': '30 min',
      'description': 'Klassische Nassrasur oder Konturenrasur inklusive Pflege.',
    },
    {
      'id': 'b1',
      'category': 'Bart',
      'title': 'Barttrimmen',
      'price': '€15–€25',
      'duration': '20 min',
      'description': 'Professionelles Barttrimmen für eine gepflegte Form.',
    },
    {
      'id': 'b2',
      'category': 'Bart',
      'title': 'Vollbartpflege',
      'price': '€25–€40',
      'duration': '30 min',
      'description':
          'Umfassende Bartpflege inklusive Waschen, Schneiden und Pflegeprodukte.',
    },
    {
      'id': 's1',
      'category': 'Spezial',
      'title': 'Balayage',
      'price': '€120–€180',
      'duration': '120 min',
      'description':
          'Sanfte Farbverläufe für einen natürlichen Look. Inklusive Beratung und Pflege.',
    },
    {
      'id': 's2',
      'category': 'Spezial',
      'title': 'Keratin‑Behandlung',
      'price': '€150–€200',
      'duration': '150 min',
      'description':
          'Glättet und pflegt das Haar mit Keratin. Langanhaltendes Ergebnis.',
    },
  ];

  late TabController _tabController;
  String? _selectedServiceId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDraftServiceId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads a previously selected service ID from shared preferences if
  /// available. This ensures the user’s selection persists across
  /// sessions.
  Future<void> _loadDraftServiceId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedServiceId = prefs.getString('draft_service_id');
    });
  }

  /// Saves the selected service ID to shared preferences and updates
  /// state. Also shows a short confirmation message.
  Future<void> _selectService(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_service_id', id);
    setState(() {
      _selectedServiceId = id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Service ausgewählt')),
    );
  }

  /// Returns the list of services filtered by the current tab
  /// selection. The TabBar index corresponds to the category order
  /// defined below.
  List<Map<String, String>> _servicesForTab(int index) {
    String category;
    switch (index) {
      case 0:
        category = 'Damen';
        break;
      case 1:
        category = 'Herren';
        break;
      case 2:
        category = 'Bart';
        break;
      default:
        category = 'Spezial';
    }
    return _services
        .where((service) => service['category'] == category)
        .toList();
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
            tabs: const [
              Tab(text: 'Damen'),
              Tab(text: 'Herren'),
              Tab(text: 'Bart'),
              Tab(text: 'Spezial'),
            ],
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
              children: List.generate(4, (index) {
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
                    final bool selected = service['id'] == _selectedServiceId;
                    return Card(
                      child: ListTile(
                        title: Text(service['title']!),
                        subtitle: Text('${service['price']} • ${service['duration']}'),
                        trailing: selected
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
        child: ElevatedButton(
          onPressed: _selectedServiceId != null
              ? () {
                  Navigator.of(context).pushNamed('/booking/select-stylist');
                }
              : null,
          child: const Text('Weiter'),
        ),
      ),
    );
  }

  /// Displays a bottom sheet with detailed information about the
  /// service. Includes a button to choose the service which stores
  /// the service ID and closes the sheet. This replicates the
  /// behavior described for the service cards【522868310347694†L128-L136】.
  void _showServiceDetails(Map<String, String> service) {
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
                    service['title']!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(service['description'] ?? ''),
              const SizedBox(height: 16),
              Text('Preis: ${service['price']}'),
              Text('Dauer: ${service['duration']}'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _selectService(service['id']!);
                  },
                  child: const Text('Service auswählen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}