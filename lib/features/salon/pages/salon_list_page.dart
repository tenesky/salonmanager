import 'package:flutter/material.dart';
import '../models/salon.dart';
import '../../../services/db_service.dart';

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
  // All salons retrieved from Supabase. Starts empty until data is loaded.
  List<Map<String, dynamic>> _allSalons = [];
  // Current list after applying search and filter criteria.
  List<Map<String, dynamic>> _filteredSalons = [];
  // Loading indicator and error state.
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _selectedRatingFilter = 'Alle';
  String _selectedPriceFilter = 'Alle';

  @override
  void initState() {
    super.initState();
    // Load salons initially with default filters.
    _loadSalons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads salons from Supabase according to the current search and
  /// filter state. This method sets loading and error flags and
  /// updates the local lists accordingly.
  Future<void> _loadSalons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final query = _searchController.text.trim();
      // Determine price filter. Supabase stores price levels in the
      // `price_level` column (e.g. '$', '$$', '$$$', '$$$$'). A value
      // of 'Alle' means no filtering.
      Set<String>? selectedPrices;
      if (_selectedPriceFilter != 'Alle') {
        selectedPrices = {_selectedPriceFilter};
      }
      // Determine minimum rating based on the selected option.
      double? minRating;
      if (_selectedRatingFilter == '4.5+') {
        minRating = 4.5;
      } else if (_selectedRatingFilter == '4.7+') {
        minRating = 4.7;
      }
      final salons = await DbService.getSalons(
        searchQuery: query.isEmpty ? null : query,
        selectedPrices: selectedPrices,
        minRating: minRating,
      );
      setState(() {
        _allSalons = salons;
        _filteredSalons = salons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden der Salons';
        _isLoading = false;
      });
    }
  }

  /// Triggers loading salons with the current filters. This is called
  /// whenever the search query or filter values change.
  void _applyFilters() {
    // Debounce or directly trigger a reload with updated filters.
    _loadSalons();
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null
                    ? Center(child: Text(_error!))
                    : (_filteredSalons.isEmpty
                        ? const Center(child: Text('Keine Salons gefunden'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _filteredSalons.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final salon = _filteredSalons[index];
                              // Extract fields with fallbacks
                              final dynamic ratingVal = salon['rating'];
                              final double rating = ratingVal is int
                                  ? ratingVal.toDouble()
                                  : (ratingVal is double ? ratingVal : 0.0);
                              final String name = (salon['name'] ?? '').toString();
                              final String priceLevel = (salon['price_level'] ?? '').toString();
                              final String address = (salon['address'] ?? '').toString();
                              final String phone = (salon['phone'] ?? '').toString();
                              final String opening = (salon['opening_hours'] ?? '').toString();
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary,
                                    child: const Icon(Icons.store, color: Colors.white),
                                  ),
                                  title: Text(name.isNotEmpty ? name : 'Unbenannter Salon'),
                                  subtitle: Row(
                                    children: [
                                      Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                                      const SizedBox(width: 4),
                                      Text(rating.toStringAsFixed(1)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.attach_money, size: 16),
                                      const SizedBox(width: 2),
                                      Text(priceLevel.isNotEmpty ? priceLevel : 'n/a'),
                                    ],
                                  ),
                                  onTap: () {
                                    // Use placeholder images for cover and logo. In a real app
                                    // these could be loaded from Supabase Storage.
                                    final detailSalon = Salon(
                                      name: name,
                                      coverImage: 'assets/background_dark.png',
                                      logoImage: 'assets/logo_full.png',
                                      address: address,
                                      openingHours: opening.replaceAll('\n', ' | '),
                                      phone: phone,
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
                          ))),
          ),
        ],
      ),
    );
  }
}
