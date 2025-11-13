import 'package:flutter/material.dart';
import '../models/salon.dart';

/// Page displaying a list of salons with search and filter options.
///
/// This implementation uses static sample data to populate the list.
/// Users can search by salon name and filter by minimum rating or price
/// level. Later the data can be fetched from a backend or local
/// database.
class SalonListPage extends StatefulWidget {
  const SalonListPage({Key? key}) : super(key: key);

  @override
  State<SalonListPage> createState() => _SalonListPageState();
}

class _SalonListPageState extends State<SalonListPage> {
  // Sample salon data. In a real implementation this would come
  // from Supabase or another backend.
  final List<Map<String, dynamic>> _allSalons = [
    {
      'name': 'Salon Elegance',
      'distance': '1,2 km',
      'rating': 4.8,
      'priceLevel': '\$\$',
    },
    {
      'name': 'Hair Couture',
      'distance': '2,5 km',
      'rating': 4.6,
      'priceLevel': '\$\$\$',
    },
    {
      'name': 'Golden Scissors',
      'distance': '3,0 km',
      'rating': 4.7,
      'priceLevel': '\$\$',
    },
    {
      'name': 'Style Studio',
      'distance': '4,1 km',
      'rating': 4.5,
      'priceLevel': '\$\$\$\$',
    },
    {
      'name': 'Beauty Bar',
      'distance': '5,0 km',
      'rating': 4.4,
      'priceLevel': '\$',
    },
  ];

  // Current list after filtering/searching.
  late List<Map<String, dynamic>> _filteredSalons;

  final TextEditingController _searchController = TextEditingController();
  String _selectedRatingFilter = 'Alle';
  String _selectedPriceFilter = 'Alle';

  @override
  void initState() {
    super.initState();
    _filteredSalons = List<Map<String, dynamic>>.from(_allSalons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Apply search and filter criteria to the list of salons.
  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredSalons = _allSalons.where((salon) {
        final name = (salon['name'] as String).toLowerCase();
        final matchesQuery = query.isEmpty || name.contains(query);
        final rating = salon['rating'] as double;
        final price = salon['priceLevel'] as String;
        bool matchesRating;
        switch (_selectedRatingFilter) {
          case '4.5+':
            matchesRating = rating >= 4.5;
            break;
          case '4.7+':
            matchesRating = rating >= 4.7;
            break;
          default:
            matchesRating = true;
        }
        bool matchesPrice;
        switch (_selectedPriceFilter) {
          case '\$':
            matchesPrice = price == '\$';
            break;
          case '\$\$':
            matchesPrice = price == '\$\$';
            break;
          case '\$\$\$':
            matchesPrice = price == '\$\$\$';
            break;
          case '\$\$\$\$':
            matchesPrice = price == '\$\$\$\$';
            break;
          default:
            matchesPrice = true;
        }
        return matchesQuery && matchesRating && matchesPrice;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salons in deiner Nähe'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Salons suchen...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRatingFilter,
                        decoration: const InputDecoration(
                          labelText: 'Bewertung',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Alle', child: Text('Alle')),
                          DropdownMenuItem(value: '4.5+', child: Text('4.5+')),
                          DropdownMenuItem(value: '4.7+', child: Text('4.7+')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRatingFilter = value;
                              _applyFilters();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriceFilter,
                        decoration: const InputDecoration(
                          labelText: 'Preisniveau',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Alle', child: Text('Alle')),
                          DropdownMenuItem(value: '\$', child: Text('\$')),
                          DropdownMenuItem(value: '\$\$', child: Text('\$\$')),
                          DropdownMenuItem(value: '\$\$\$', child: Text('\$\$\$')),
                          DropdownMenuItem(value: '\$\$\$\$', child: Text('\$\$\$\$')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPriceFilter = value;
                              _applyFilters();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredSalons.isEmpty
                ? const Center(child: Text('Keine Salons gefunden'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredSalons.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final salon = _filteredSalons[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: const Icon(Icons.store, color: Colors.white),
                          ),
                          title: Text(salon['name'] as String),
                          subtitle: Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                              const SizedBox(width: 4),
                              Text((salon['rating'] as double).toString()),
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 4),
                              Text(salon['distance'] as String),
                              const SizedBox(width: 8),
                              const Icon(Icons.attach_money, size: 16),
                              const SizedBox(width: 2),
                              Text(salon['priceLevel'] as String),
                            ],
                          ),
                          onTap: () {
                            final detailSalon = Salon(
                              name: salon['name'] as String,
                              coverImage: 'assets/background_dark.png',
                              logoImage: 'assets/logo_full.png',
                              address: 'Musterstraße 1, 12345 Musterstadt',
                              openingHours: 'Mo–Sa 09:00–18:00',
                              phone: '+49 123 4567890',
                            );
                            Navigator.pushNamed(
                              context,
                              '/salon-detail',
                              arguments: detailSalon,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
