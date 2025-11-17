import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/auth_service.dart';

/// Model representing a salon location with basic attributes used for
/// filtering and display on the map. In a real application this
/// information would come from the backend. Here we provide a small
/// static list to enable the interactive map and filter functionality.
class SalonLocation {
  final String name;
  final LatLng location;
  final String priceLevel; // e.g. '$', '$$', '$$$'
  final double rating; // 0–5 stars
  final bool hasFreeAppointments;

  const SalonLocation({
    required this.name,
    required this.location,
    required this.priceLevel,
    required this.rating,
    required this.hasFreeAppointments,
  });
}

/// Page displaying an interactive Leaflet map with salons. A floating
/// filter button opens a bottom sheet allowing the user to filter
/// salons by distance, price, rating and availability. Tapping a
/// marker shows a bottom sheet with salon details and a call to
/// action. This page corresponds to the specification for the
/// interactive map & filter drawer (Modul B, Screen 11/12)【522868310347694†L209-L214】.
class SalonsMapPage extends StatefulWidget {
  const SalonsMapPage({Key? key}) : super(key: key);

  @override
  State<SalonsMapPage> createState() => _SalonsMapPageState();
}

class _SalonsMapPageState extends State<SalonsMapPage> {
  // List of example salons. Coordinates are roughly around Munich, DE.
  final List<SalonLocation> _salons = const [
    SalonLocation(
      name: 'Salon Elegance',
      location: LatLng(48.137154, 11.576124),
      priceLevel: '\$\$',
      rating: 4.8,
      hasFreeAppointments: true,
    ),
    SalonLocation(
      name: 'Hair Couture',
      location: LatLng(48.1365, 11.5800),
      priceLevel: '\$\$\$',
      rating: 4.6,
      hasFreeAppointments: false,
    ),
    SalonLocation(
      name: 'Golden Scissors',
      location: LatLng(48.1390, 11.5750),
      priceLevel: '\$\$',
      rating: 4.7,
      hasFreeAppointments: true,
    ),
    SalonLocation(
      name: 'City Cuts',
      location: LatLng(48.1351, 11.5793),
      priceLevel: '\$',
      rating: 4.4,
      hasFreeAppointments: true,
    ),
    SalonLocation(
      name: 'Stylish Trends',
      location: LatLng(48.1385, 11.5732),
      priceLevel: '\$\$\$',
      rating: 4.9,
      hasFreeAppointments: false,
    ),
  ];

  // Filter state
  double _maxDistance = 10.0; // kilometres
  Set<String> _selectedPriceLevels = {};
  double _minRating = 0.0;
  bool _onlyFree = false;

  // Whether the list view is shown instead of the map. When true, a list
  // of salons is displayed instead of the interactive map. This flag
  // toggles via the Map/List buttons in the top overlay.
  bool _showList = false;

  // Controller for the search field. Typing into this field filters
  // salons by their names. The listener clears the selected salon
  // whenever the search query changes.
  final TextEditingController _searchController = TextEditingController();

  // Holds the currently selected salon. When non-null, a preview card
  // appears at the bottom of the screen showing details about the salon.
  SalonLocation? _selectedSalon;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    // Clear the selected salon whenever the search input changes.
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedSalon = null;
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose the search controller to free resources.
    _searchController.dispose();
    super.dispose();
  }

  /// Requests location permissions and obtains the current position
  /// using the Geolocator plugin. Once the location is retrieved,
  /// update the map centre and move the map. If permission is
  /// denied, the map remains at its default centre.
  Future<void> _loadUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition();
      final LatLng location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _mapCenter = location;
      });
      // Move the map after the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final zoom = _mapController.zoom;
          _mapController.move(location, zoom == 0 ? 14.0 : zoom);
        } catch (_) {
          // ignore
        }
      });
    } catch (_) {
      // if any error occurs, do nothing
    }
  }

  // Map centre. Initially set to Munich; will be updated to the
  // user's current location when permissions are granted. Using a
  // mutable variable allows us to update the centre after loading.
  LatLng _mapCenter = const LatLng(48.137154, 11.576124);

  /// The user's current location. When loaded, this will be used to
  /// centre the map and filter salons by distance.
  LatLng? _userLocation;

  /// Controller for the map so we can programmatically move it to
  /// the current location once loaded.
  final MapController _mapController = MapController();

  /// Returns a filtered list of salons based on the current filter
  /// settings. Distance is computed from a fixed centre for
  /// demonstration purposes. The `latlong2` Distance helper is used
  /// to calculate kilometres between points.
  List<SalonLocation> get _filteredSalons {
    final distanceCalc = Distance();
    // Normalise search query to lower case for case-insensitive matching.
    final query = _searchController.text.trim().toLowerCase();
    return _salons.where((salon) {
      // Filter by search query: ensure the salon name contains the query.
      if (query.isNotEmpty && !salon.name.toLowerCase().contains(query)) {
        return false;
      }
      // Filter by distance
      final distKm = distanceCalc.as(LengthUnit.Kilometer, _mapCenter, salon.location);
      if (distKm > _maxDistance) return false;
      // Filter by price level if any selected
      if (_selectedPriceLevels.isNotEmpty && !_selectedPriceLevels.contains(salon.priceLevel)) {
        return false;
      }
      // Filter by rating
      if (salon.rating < _minRating) return false;
      // Filter by availability
      if (_onlyFree && !salon.hasFreeAppointments) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salons auf der Karte'),
        actions: [
          // Optional filter button in the AppBar to open the filter drawer
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      // Use a Stack so that we can overlay filter chips on top of the map.
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _mapCenter,
              zoom: 14.0,
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
                markers: _filteredSalons.map<Marker>((salon) {
                  return Marker(
                    point: salon.location,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showSalonDetails(salon),
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: theme.brightness == Brightness.dark
                            ? Colors.amber.shade400
                            : Colors.amber.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          // Positioned filter chips above the map. This row shows the
          // current filter selections. Tapping on distance, price or
          // rating chips opens the detailed filter sheet. The “nur
          // freie Termine” chip toggles immediately.
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8.0,
                children: [
                  // Distance chip
                  FilterChip(
                    label: Text('Entfernung: ${_maxDistance.toStringAsFixed(0)} km'),
                    selected: true,
                    onSelected: (_) => _openFilterSheet(),
                  ),
                  // Price level chip
                  FilterChip(
                    label: Text(_selectedPriceLevels.isEmpty
                        ? 'Preislevel'
                        : _selectedPriceLevels.join(', ')),
                    selected: _selectedPriceLevels.isNotEmpty,
                    onSelected: (_) => _openFilterSheet(),
                  ),
                  // Rating chip
                  FilterChip(
                    label: Text('Bewertung: ${_minRating.toStringAsFixed(1)}+'),
                    selected: _minRating > 0,
                    onSelected: (_) => _openFilterSheet(),
                  ),
                  // Only free appointments chip toggles directly
                  FilterChip(
                    label: const Text('Nur freie Termine'),
                    selected: _onlyFree,
                    onSelected: (_) {
                      setState(() => _onlyFree = !_onlyFree);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a row of filter chips that reflect the current filter
  /// selections. This helper could be extended to support more
  /// granular control or to open a dedicated filter drawer. Currently,
  /// distance, price level and rating chips open the bottom sheet,
  /// while the "Nur freie Termine" chip toggles the boolean flag
  /// directly.
  // Widget _buildFilterChips() {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Wrap(
  //       spacing: 8.0,
  //       children: [
  //         FilterChip(
  //           label: Text('Entfernung: ${_maxDistance.toStringAsFixed(0)} km'),
  //           selected: true,
  //           onSelected: (_) => _openFilterSheet(),
  //         ),
  //         FilterChip(
  //           label: Text(_selectedPriceLevels.isEmpty ? 'Preislevel' : _selectedPriceLevels.join(', ')),
  //           selected: _selectedPriceLevels.isNotEmpty,
  //           onSelected: (_) => _openFilterSheet(),
  //         ),
  //         FilterChip(
  //           label: Text('Bewertung: ${_minRating.toStringAsFixed(1)}+'),
  //           selected: _minRating > 0,
  //           onSelected: (_) => _openFilterSheet(),
  //         ),
  //         FilterChip(
  //           label: const Text('Nur freie Termine'),
  //           selected: _onlyFree,
  //           onSelected: (_) {
  //             setState(() => _onlyFree = !_onlyFree);
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Opens a bottom sheet with filtering options. When the user taps
  /// “Anwenden”, the filter selections are stored in the state and
  /// the map markers update accordingly. Sliders and chips are used
  /// for intuitive selection of distance, price and rating, with a
  /// toggle for only showing salons with free appointments.
  void _openFilterSheet() {
    double tempDistance = _maxDistance;
    Set<String> tempPriceLevels = {..._selectedPriceLevels};
    double tempMinRating = _minRating;
    bool tempOnlyFree = _onlyFree;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Maximale Entfernung (km): ${tempDistance.toStringAsFixed(1)}'),
                    Slider(
                      value: tempDistance,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: tempDistance.toStringAsFixed(1),
                      onChanged: (value) {
                        setModalState(() => tempDistance = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Preisniveau'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: ['\$', '\$\$', '\$\$\$'].map((level) {
                        final isSelected = tempPriceLevels.contains(level);
                        return FilterChip(
                          label: Text(level),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                tempPriceLevels.add(level);
                              } else {
                                tempPriceLevels.remove(level);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Mindestbewertung: ${tempMinRating.toStringAsFixed(1)}'),
                    Slider(
                      value: tempMinRating,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: tempMinRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setModalState(() => tempMinRating = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Nur freie Termine'),
                      value: tempOnlyFree,
                      onChanged: (value) {
                        setModalState(() => tempOnlyFree = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _maxDistance = tempDistance;
                            _selectedPriceLevels = tempPriceLevels;
                            _minRating = tempMinRating;
                            _onlyFree = tempOnlyFree;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Anwenden'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Displays the details of a selected salon in a bottom sheet. The
  /// card shows basic information and a call‑to‑action button. In
  /// keeping with the specification, the card uses the gold accent
  /// colour and provides a CTA “Jetzt buchen”【522868310347694†L209-L214】.
  void _showSalonDetails(SalonLocation salon) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
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
                    salon.name,
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
                  Text(salon.rating.toStringAsFixed(1)),
                  const SizedBox(width: 16),
                  const Icon(Icons.attach_money, size: 20),
                  const SizedBox(width: 2),
                  Text(salon.priceLevel),
                ],
              ),
              const SizedBox(height: 12),
              Text(salon.hasFreeAppointments ? 'Freie Termine verfügbar' : 'Keine freien Termine'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Salon "${salon.name}" ausgewählt (Demo)')),
                    );
                  },
                  child: const Text('Jetzt buchen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}