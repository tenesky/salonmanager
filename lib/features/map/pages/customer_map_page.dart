import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../common/themed_background.dart';
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';

/// A full screen interactive map page for customers.  This page is
/// shown when the user taps the map preview on the home screen.  It
/// allows switching between map and list views, filtering by price,
/// rating and availability, and viewing salon details in an overlay.
/// The UI follows the design provided by the client: a dark themed
/// background, a toggle for Map/List, a search bar with filter
/// button, and a bottom nav bar matching the rest of the app.  When
/// the user selects a marker, a card with the salon name, price
/// level, rating, a short description and a booking button appears
/// above the navigation bar.
class CustomerMapPage extends StatefulWidget {
  const CustomerMapPage({Key? key}) : super(key: key);

  @override
  State<CustomerMapPage> createState() => _CustomerMapPageState();
}

class _CustomerMapPageState extends State<CustomerMapPage> {
  LatLng? _userLocation;
  bool _loadingLocation = true;
  bool _showMap = true;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _salons = [];
  List<Marker> _salonMarkers = [];
  Map<String, dynamic>? _selectedSalon;

  // Filter state
  Set<String> _selectedPrices = {};
  double _minRating = 0.0;
  bool _onlyFree = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadSalons();
  }

  /// Requests the user's location if permission is granted.  If
  /// permission is denied, the map will still render but centre on a
  /// default location (Munich).  Errors are ignored silently.
  Future<void> _loadUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        _userLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (_) {
      // ignore
    }
    if (mounted) {
      setState(() => _loadingLocation = false);
    }
  }

  /// Loads salons from the backend applying the current search and
  /// filter settings.  After fetching the records we build marker
  /// widgets for the map.  Errors are ignored silently.
  Future<void> _loadSalons() async {
    try {
      final salons = await DbService.getSalons(
        searchQuery: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        selectedPrices: _selectedPrices,
        minRating: _minRating > 0 ? _minRating : null,
        onlyFree: _onlyFree,
      );
      final List<Marker> markers = [];
      for (final salon in salons) {
        final lat = salon['latitude'] as double?;
        final lng = salon['longitude'] as double?;
        if (lat != null && lng != null) {
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedSalon = salon);
                },
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _salons = salons;
          _salonMarkers = markers;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  /// Opens a bottom sheet allowing the user to adjust filters.  The
  /// filter fields are the same as those supported by
  /// [DbService.getSalons].  When the user taps "Anwenden", the
  /// temporary selections are committed to the state and the list is
  /// reloaded.
  void _openFilterSheet() {
    double tempMinRating = _minRating;
    bool tempOnlyFree = _onlyFree;
    Set<String> tempPrices = {..._selectedPrices};
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter',
                          style:
                              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Preisniveau'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['\$', '\$\$', '\$\$\$'].map((level) {
                        final selected = tempPrices.contains(level);
                        return FilterChip(
                          label: Text(level),
                          selected: selected,
                          onSelected: (sel) {
                            setModalState(() {
                              if (sel) {
                                tempPrices.add(level);
                              } else {
                                tempPrices.remove(level);
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
                      onChanged: (val) {
                        setModalState(() => tempMinRating = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Nur freie Termine'),
                      value: tempOnlyFree,
                      onChanged: (val) {
                        setModalState(() => tempOnlyFree = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedPrices = tempPrices;
                            _minRating = tempMinRating;
                            _onlyFree = tempOnlyFree;
                          });
                          Navigator.pop(context);
                          _loadSalons();
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

  /// Builds the interactive map view.  It shows the user's location
  /// (if available) and markers for each salon.  When a marker is
  /// tapped the selected salon is stored and displayed in the
  /// overlay.  While the location is loading a progress indicator
  /// appears.
  Widget _buildMap() {
    final theme = Theme.of(context);
    // If the user location is unknown, show a world view (zoomed out)
    final LatLng defaultCenter = const LatLng(0.0, 0.0);
    final double defaultZoom = _userLocation == null ? 2.0 : 13.0;
    return FlutterMap(
      options: MapOptions(
        center: _userLocation ?? defaultCenter,
        zoom: defaultZoom,
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.salonmanager',
        ),
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
            ],
          ),
        if (_salonMarkers.isNotEmpty) MarkerLayer(markers: _salonMarkers),
      ],
    );
  }

  /// Builds a simple list view of salons when the user switches to
  /// "List" view.  For now this displays the names and basic info
  /// only.  A more detailed implementation could provide sorting
  /// options and grouping.
  Widget _buildList() {
    final brightness = Theme.of(context).brightness;
    return ListView.separated(
      padding: const EdgeInsets.only(top: 120, bottom: 120, left: 16, right: 16),
      itemCount: _salons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final salon = _salons[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _selectedSalon = salon);
              setState(() => _showMap = true);
            },
            child: Container(
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.image,
                      color: brightness == Brightness.dark ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon['name'] as String? ?? 'Salon',
                          style: TextStyle(
                            color: brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          salon['price_level'] as String? ?? '',
                          style: TextStyle(
                            color: brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/booking/select-salon');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Buchen'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return Scaffold(
      body: ThemedBackground(
        child: Container(
          // Apply a semi‑transparent overlay to ensure the background
          // pattern remains visible while the UI elements remain legible.
          color: brightness == Brightness.dark
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.4),
          child: SafeArea(
            child: Stack(
              children: [
                // Map or list view fills the available space.
                Positioned.fill(
                  child: _showMap ? _buildMap() : _buildList(),
                ),
                // Loading indicator while waiting for location
                if (_loadingLocation)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                // Top overlay with toggle, search bar and filter button
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle row
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleButton(
                              label: 'Map',
                              icon: Icons.map,
                              active: _showMap,
                              onTap: () {
                                setState(() {
                                  _showMap = true;
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildToggleButton(
                              label: 'List',
                              icon: Icons.list,
                              active: !_showMap,
                              onTap: () {
                                setState(() {
                                  _showMap = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Search and filter row
                      Row(
                        children: [
                          // Filter button
                          TextButton.icon(
                            onPressed: _openFilterSheet,
                            style: TextButton.styleFrom(
                              backgroundColor: brightness == Brightness.dark
                                  ? Colors.black.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 12.0),
                            ),
                            icon: Icon(
                              Icons.filter_alt,
                              color: accent,
                            ),
                            label: Text(
                              'Filter',
                              style: TextStyle(
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(
                                  color: brightness == Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: brightness == Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                filled: true,
                                fillColor: brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24.0),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 16),
                              ),
                              onChanged: (_) {
                                _loadSalons();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Salon details overlay
                if (_selectedSalon != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 72,
                    child: Container(
                      decoration: BoxDecoration(
                        color: brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.8)
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedSalon!['name'] as String? ?? 'Salon',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              // Price level represented as EUR symbols
                              Text(
                                _selectedSalon!['price_level'] as String? ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Rating stars
                          Row(
                            children: [
                              for (int i = 1; i <= 5; i++)
                                Icon(
                                  i <= ((_selectedSalon!['rating'] as num?)?.round() ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: accent,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Beschreibung. Hier könnte eine kurze Beschreibung des Salons stehen.',
                            style: TextStyle(
                              fontSize: 14,
                              color: brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Navigate to salon info page with details
                                    Navigator.pushNamed(
                                      context,
                                      '/salon-info',
                                      arguments: _selectedSalon,
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: accent,
                                    side: BorderSide(color: accent),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: const Text('Mehr Infos'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: brightness == Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                    backgroundColor: accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/booking/select-salon');
                                  },
                                  child: const Text('Buchen'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: accent,
        unselectedItemColor:
            brightness == Brightness.dark ? Colors.white70 : Colors.black54,
        backgroundColor:
            brightness == Brightness.dark ? Colors.black : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: 'Galerie',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Buchen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Termine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Pop this page back to home
              Navigator.of(context).pop();
              break;
            case 1:
              Navigator.of(context).pushNamed('/gallery');
              break;
            case 2:
              Navigator.of(context).pushNamed('/booking/select-salon');
              break;
            case 3:
              if (!AuthService.isLoggedIn()) {
                Navigator.of(context).pushNamed('/login');
              } else {
                Navigator.of(context).pushNamed('/profile/bookings');
              }
              break;
            case 4:
              if (!AuthService.isLoggedIn()) {
                Navigator.of(context).pushNamed('/login');
              } else {
                Navigator.of(context).pushNamed('/crm/customer', arguments: {'id': 1});
              }
              break;
          }
        },
      ),
    );
  }

  /// Builds a small toggle button used in the map/list switch.  The
  /// active button is filled with the accent colour; inactive
  /// buttons are transparent with coloured text and icon.  This is
  /// duplicated from the home page to avoid a cross‑file import of
  /// a private helper.
  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return InkWell(
      borderRadius: BorderRadius.circular(16.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? Colors.black
                  : (brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active
                    ? Colors.black
                    : (brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}