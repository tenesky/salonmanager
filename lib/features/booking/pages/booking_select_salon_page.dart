import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';

/// First step of the booking wizard: select a salon. This screen
/// provides a search bar, filter chips (Distanz, Preis, Bewertung)
/// and a toggle for „nur freie Termine“. Users can switch between
/// list‑ and map‑view to choose a salon. Once a salon is selected the
/// progress indicator shows step 1/8 and the "Weiter" button
/// becomes active.
class BookingSelectSalonPage extends StatefulWidget {
  const BookingSelectSalonPage({Key? key}) : super(key: key);

  @override
  State<BookingSelectSalonPage> createState() => _BookingSelectSalonPageState();
}

class _BookingSelectSalonPageState extends State<BookingSelectSalonPage> {
  /// Salons loaded from Supabase. Each entry contains id, name,
  /// rating, price_level, next_slot, has_free, latitude and
  /// longitude. Initially empty until [_loadSalons] runs.
  List<Map<String, dynamic>> _salons = [];

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double? _maxDistance;
  Set<String> _selectedPrices = {};
  double? _minRating;
  bool _onlyFree = false;

  // Map/List toggle
  bool _showMap = false;

  // Selected salon ID stored in the booking draft
  String? _selectedSalonId;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
    // Immediately load salons when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSalons());
  }

  /// Checks whether the user is authenticated via Supabase. If not,
  /// redirects to the login page. Otherwise proceeds to load any stored
  /// draft salon ID.
  void _checkAuthAndLoad() {
    // Defer navigation until after the first frame to avoid build errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthService.isLoggedIn()) {
        Navigator.of(context).pushNamed('/login');
      } else {
        _loadDraftSalonId();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads a previously selected salon ID from shared preferences, if
  /// available. This ensures that a selection made in a previous
  /// session is restored.
  Future<void> _loadDraftSalonId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSalonId = prefs.getString('draft_salon_id');
    });
  }

  /// Saves the selected salon ID to shared preferences and updates
  /// state. Also shows a short confirmation message.
  Future<void> _selectSalon(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_salon_id', id);
    setState(() {
      _selectedSalonId = id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salon ausgewählt')),
    );
  }

  /// Loads salons from the backend based on the current search and
  /// filter criteria. Uses [DbService.getSalons] to retrieve the
  /// results. Any errors are silently swallowed.
  Future<void> _loadSalons() async {
    try {
      final salons = await DbService.getSalons(
        searchQuery: _searchQuery,
        selectedPrices: _selectedPrices,
        minRating: _minRating,
        onlyFree: _onlyFree,
      );
      setState(() {
        _salons = salons;
      });
    } catch (_) {
      // ignore
    }
  }

  /// Returns a list of salons filtered according to the search query
  /// and filter settings. The filters include distance, price,
  /// minimum rating and availability.
  List<Map<String, dynamic>> get _filteredSalons {
    return _salons.where((salon) {
      final name = (salon['name']?.toString() ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
        return false;
      }
      // Distance filtering is not applied because no distance field is
      // available in the Supabase data.
      if (_selectedPrices.isNotEmpty && !_selectedPrices.contains(salon['price_level'])) {
        return false;
      }
      if (_minRating != null) {
        final dynamic rating = salon['rating'];
        double r;
        if (rating is int) {
          r = rating.toDouble();
        } else if (rating is double) {
          r = rating;
        } else {
          r = 0.0;
        }
        if (r < _minRating!) {
          return false;
        }
      }
      if (_onlyFree && !(salon['has_free'] as bool? ?? false)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Toggles between the list and map view.
  void _toggleView() {
    setState(() {
      _showMap = !_showMap;
    });
  }

  /// Opens a bottom sheet with salon details when a marker is tapped.
  /// Allows the user to select the salon directly from the map.
  void _showMapSalonDetails(Map<String, dynamic> salon) {
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
                    salon['name'] as String,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600),
                  const SizedBox(width: 4),
                  // The rating from Supabase can be int or double. Convert
                  // gracefully and format with one decimal place.
                  Builder(builder: (_) {
                    final dynamic ratingDyn = salon['rating'];
                    double rating;
                    if (ratingDyn is int) {
                      rating = ratingDyn.toDouble();
                    } else if (ratingDyn is double) {
                      rating = ratingDyn;
                    } else {
                      rating = 0.0;
                    }
                    return Text(rating.toStringAsFixed(1));
                  }),
                  const SizedBox(width: 16),
                  const Icon(Icons.attach_money, size: 20),
                  const SizedBox(width: 2),
                  Text(salon['price_level'] as String),
                ],
              ),
              const SizedBox(height: 12),
              Text((salon['has_free'] as bool? ?? false)
                  ? 'Freie Termine verfügbar'
                  : 'Keine freien Termine'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _selectSalon(salon['id'] as String);
                  },
                  child: const Text('Diesen Salon wählen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSalons;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon wählen'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator and step label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 1 / 8,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('1/8'),
              ],
            ),
          ),
          // Search field and view toggle button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Salon, Stadt, PLZ',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                      _loadSalons();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _toggleView,
                  tooltip: _showMap ? 'Listenansicht' : 'Kartenansicht',
                  icon: Icon(_showMap ? Icons.list : Icons.map),
                ),
              ],
            ),
          ),
          // Filter chips and free‑slots toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Distance chips
                Wrap(
                  spacing: 8.0,
                  children: [
                    2.0,
                    5.0,
                    10.0,
                  ].map((double dist) {
                    final bool selected = _maxDistance == dist;
                    return ChoiceChip(
                      label: Text('≤${dist.toInt()} km'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _maxDistance = selected ? null : dist;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(width: 8),
                // Price chips (multi select)
                Wrap(
                  spacing: 8.0,
                  children: ['\$', '\$\$', '\$\$\$'].map((String price) {
                    final bool selected = _selectedPrices.contains(price);
                    return FilterChip(
                      label: Text(price),
                      selected: selected,
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            _selectedPrices.add(price);
                          } else {
                            _selectedPrices.remove(price);
                          }
                        });
                        _loadSalons();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(width: 8),
                // Rating chips
                Wrap(
                  spacing: 8.0,
                  children: [4.0, 4.5, 5.0].map((double rating) {
                    final bool selected = _minRating == rating;
                    return ChoiceChip(
                      label: Text('≥${rating.toString()}★'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _minRating = selected ? null : rating;
                        });
                        _loadSalons();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Text('nur freie'),
                    Switch(
                      value: _onlyFree,
                      onChanged: (bool value) {
                            setState(() {
                              _onlyFree = value;
                            });
                            _loadSalons();
                          },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Main content: list or map
          Expanded(
            child: _showMap ? _buildMapView(filtered) : _buildListView(filtered),
          ),
        ],
      ),
      // Continue button at bottom
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedSalonId != null
              ? () {
                  // Navigate to the next step of the booking wizard. For
                  // now this is a placeholder route.
                  Navigator.of(context).pushNamed('/booking/select-service');
                }
              : null,
          child: const Text('Weiter'),
        ),
      ),
    );
  }

  /// Builds the list view of salons. Each item shows basic details and
  /// allows selection. The selected item is indicated with a check
  /// mark. If no salons match the filters a message is shown.
  Widget _buildListView(List<Map<String, dynamic>> salons) {
    if (salons.isEmpty) {
      return const Center(
        child: Text('Keine Salons gefunden – bitte Filter anpassen.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: salons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final salon = salons[index];
        final bool isSelected = salon['id'] == _selectedSalonId;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.store, color: Colors.white),
            ),
            title: Text(salon['name'] as String),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Rating
                    Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Builder(builder: (_) {
                      final dynamic ratingDyn = salon['rating'];
                      double rating;
                      if (ratingDyn is int) {
                        rating = ratingDyn.toDouble();
                      } else if (ratingDyn is double) {
                        rating = ratingDyn;
                      } else {
                        rating = 0.0;
                      }
                      return Text(rating.toStringAsFixed(1));
                    }),
                    const SizedBox(width: 8),
                    // Price level
                    const Icon(Icons.attach_money, size: 16),
                    const SizedBox(width: 2),
                    Text(salon['price_level'] as String),
                    const SizedBox(width: 8),
                    // Badge for next slot
                    if ((salon['next_slot'] ?? '').toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          salon['next_slot'] as String,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () => _selectSalon(salon['id'] as String),
          ),
        );
      },
    );
  }

  /// Builds the map view using FlutterMap. Markers are shown for each
  /// filtered salon and tapping a marker opens a bottom sheet to
  /// select it. The map uses OpenStreetMap tiles. The same filter
  /// logic applies as in the list view.
  Widget _buildMapView(List<Map<String, dynamic>> salons) {
    // Determine the initial centre. Use the first salon or a default.
    // Determine the initial centre. Use the first salon's coordinates or a
    // default location (Munich) if no salons are available. Convert
    // numeric fields safely to double.
    final LatLng centre;
    if (salons.isNotEmpty) {
      final first = salons.first;
      final latNum = first['latitude'];
      final lngNum = first['longitude'];
      double lat = latNum is num ? latNum.toDouble() : 48.137154;
      double lng = lngNum is num ? lngNum.toDouble() : 11.576124;
      centre = LatLng(lat, lng);
    } else {
      centre = const LatLng(48.137154, 11.576124);
    }
    return FlutterMap(
      options: MapOptions(
        center: centre,
        zoom: 13.5,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.salonmanager',
        ),
        MarkerLayer(
          // Explicitly type the iterable as List<Marker>. Convert lat/lng to
          // LatLng objects for marker positions.
          markers: salons.map<Marker>((salon) {
            final latNum = salon['latitude'];
            final lngNum = salon['longitude'];
            double lat = latNum is num ? latNum.toDouble() : 0.0;
            double lng = lngNum is num ? lngNum.toDouble() : 0.0;
            final LatLng point = LatLng(lat, lng);
            return Marker(
              point: point,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showMapSalonDetails(salon),
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.amber.shade400
                      : Colors.amber.shade700,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}