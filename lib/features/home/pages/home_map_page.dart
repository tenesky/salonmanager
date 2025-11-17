import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Import our services and models.  DbService provides access to the
// Supabase backend for loading salons.  AuthService is used to
// determine navigation targets based on the user's login status.
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';
// Reuse the SalonLocation model defined in the salons map page.  This
// describes a salon with a name, location, price level, rating and
// whether free appointments are available.
import '../../map/pages/salons_map_page.dart' show SalonLocation;

/// A full screen map page that replicates the design shown in the
/// specification for the interactive map.  This page appears when
/// the user taps on the mini map in the home page.  It displays a
/// large map with nearby salons, a search field, map/list toggle,
/// filter button and a bottom navigation bar.  When a marker is
/// tapped, a preview card with salon details and a booking button
/// appears at the bottom of the screen.  Users can toggle to a list
/// view via the "List" button.
class HomeMapPage extends StatefulWidget {
  const HomeMapPage({Key? key}) : super(key: key);

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  // List of salons loaded from Supabase.  Initially empty; will be
  // populated in initState via _loadSalons().
  List<SalonLocation> _salons = [];

  // Indicates whether salons are being loaded.  This flag could be used
  // to show a loading indicator, but for simplicity we ignore it in
  // the UI and only use it internally to prevent duplicate loads.
  bool _loadingSalons = false;

  // Filter state used by the search and filter controls.
  double _maxDistance = 10.0; // kilometres
  Set<String> _selectedPriceLevels = {};
  double _minRating = 0.0;
  bool _onlyFree = false;

  // Controls whether the list view is shown instead of the map.  When
  // true the list is visible; when false the map is visible.
  bool _showList = false;

  // Controller for the search bar to filter salons by name.
  final TextEditingController _searchController = TextEditingController();

  // The currently selected salon for which a preview card is displayed.
  SalonLocation? _selectedSalon;

  // Map centre.  Initially set to Munich; will be updated to the
  // user's current location when permissions are granted.
  LatLng _mapCenter = const LatLng(48.137154, 11.576124);

  /// The user's current location.  When loaded, this will be used to
  /// centre the map and filter salons by distance.
  LatLng? _userLocation;

  /// Controller for the map to allow programmatic control such as
  /// moving to the user's location.
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadSalons();
    // Clear the selected salon whenever the search term changes.
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
    _searchController.dispose();
    super.dispose();
  }

  /// Loads salons from the Supabase backend.  This method fetches a
  /// list of salons and maps them into [SalonLocation] objects used
  /// by the UI.  Errors are silently ignored so the page still loads
  /// without data if the network fails.
  Future<void> _loadSalons() async {
    if (_loadingSalons) return;
    setState(() {
      _loadingSalons = true;
    });
    try {
      final List<Map<String, dynamic>> data = await DbService.getSalons();
      final List<SalonLocation> salons = [];
      for (final Map<String, dynamic> row in data) {
        final lat = row['latitude'] as double?;
        final lng = row['longitude'] as double?;
        final String name = row['name']?.toString() ?? 'Salon';
        final double rating = (row['rating'] as num?)?.toDouble() ?? 0.0;
        final String price = row['price_level']?.toString() ?? '';
        final bool free = row['has_free'] == true;
        if (lat != null && lng != null) {
          salons.add(SalonLocation(
            name: name,
            location: LatLng(lat, lng),
            priceLevel: price,
            rating: rating,
            hasFreeAppointments: free,
          ));
        }
      }
      if (mounted) {
        setState(() {
          _salons = salons;
        });
      }
    } catch (_) {
      // ignore errors; _salons remains empty
    } finally {
      if (mounted) {
        setState(() {
          _loadingSalons = false;
        });
      }
    }
  }

  /// Fetches the user's current location and updates the map centre.  If
  /// permission is denied the current location remains unchanged.
  Future<void> _loadUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }
      final Position position = await Geolocator.getCurrentPosition();
      final LatLng location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _mapCenter = location;
      });
      // Move the map after the next frame is rendered.  This avoids
      // exceptions if the map has not been built yet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final double zoom = _mapController.zoom;
          _mapController.move(location, zoom == 0 ? 14.0 : zoom);
        } catch (_) {
          // ignore errors if controller not ready
        }
      });
    } catch (_) {
      // ignore any errors obtaining location
    }
  }

  /// Computes the filtered list of salons based on the search query and
  /// filter settings.  The search filters by salon name.  The
  /// distance is measured from [_mapCenter].
  List<SalonLocation> get _filteredSalons {
    final Distance distanceCalc = Distance();
    final String query = _searchController.text.trim().toLowerCase();
    return _salons.where((salon) {
      if (query.isNotEmpty && !salon.name.toLowerCase().contains(query)) {
        return false;
      }
      // Filter by distance from the current map centre
      final double distKm =
          distanceCalc.as(LengthUnit.Kilometer, _mapCenter, salon.location);
      if (distKm > _maxDistance) return false;
      // Filter by price level
      if (_selectedPriceLevels.isNotEmpty &&
          !_selectedPriceLevels.contains(salon.priceLevel)) {
        return false;
      }
      // Filter by rating
      if (salon.rating < _minRating) return false;
      // Filter by availability
      if (_onlyFree && !salon.hasFreeAppointments) return false;
      return true;
    }).toList();
  }

  /// Opens the filter bottom sheet allowing the user to adjust distance,
  /// price level, rating and availability filters.  Temporary values
  /// are stored in local variables and applied when the user taps
  /// "Anwenden".
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
                          style:
                              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Maximale Entfernung (km): '
                        '${tempDistance.toStringAsFixed(1)}'),
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
                      children: ['$', '$$', '$$$'].map((level) {
                        final bool isSelected = tempPriceLevels.contains(level);
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

  /// Builds a toggle button for the map/list switch.  The active
  /// button is filled with the accent colour; inactive buttons are
  /// transparent with coloured text and icon.
  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
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

  /// Builds the search bar.  Typing in the field updates the filter.
  Widget _buildSearchBar(ThemeData theme) {
    final brightness = theme.brightness;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: TextStyle(
          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
        ),
        filled: true,
        fillColor: brightness == Brightness.dark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
    );
  }

  /// Builds the FlutterMap widget displaying markers for each salon.
  Widget _buildMapView(ThemeData theme) {
    final brightness = theme.brightness;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _mapCenter,
        zoom: 14.0,
        minZoom: 5,
        maxZoom: 18,
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
        MarkerLayer(
          markers: _filteredSalons.map((salon) {
            final bool isSelected = _selectedSalon == salon;
            return Marker(
              point: salon.location,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSalon = salon;
                    _showList = false;
                  });
                },
                child: Icon(
                  Icons.location_pin,
                  size: isSelected ? 48 : 40,
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : (brightness == Brightness.dark
                          ? Colors.amber.shade200
                          : Colors.amber.shade700),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds a list view of salons.  Each card displays the same
  /// information as the preview card.  Tapping a card selects the
  /// salon and opens the detail page.
  Widget _buildListView(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 120.0, bottom: 120.0),
      itemCount: _filteredSalons.length,
      itemBuilder: (context, index) {
        final salon = _filteredSalons[index];
        return _buildSalonPreviewCard(
          context,
          salon,
          inList: true,
          onTapCard: () => _openSalonDetail(salon),
          onTapBook: () => _startBooking(salon),
        );
      },
    );
  }

  /// Opens the detailed salon page for the given [salon].  A map
  /// containing the salon details is passed as arguments to the route.
  void _openSalonDetail(SalonLocation salon) {
    final Map<String, dynamic> args = {
      'name': salon.name,
      'rating': salon.rating,
      'price_level': salon.priceLevel,
      // Provide empty strings for optional fields.  The detail page
      // displays sensible defaults when these are empty.
      'description': '',
      'opening_hours': '',
      'contact': '',
      'image_url': '',
      'logo_image': '',
    };
    Navigator.of(context).pushNamed('/salon-info', arguments: args);
  }

  /// Launches the booking wizard for the given [salon].  If the
  /// user is not logged in they are redirected to the login page.
  void _startBooking(SalonLocation salon) {
    if (!AuthService.isLoggedIn()) {
      Navigator.of(context).pushNamed('/login');
    } else {
      Navigator.of(context).pushNamed('/booking/select-salon');
    }
  }

  /// Builds a preview card for a salon.  This widget is used both in
  /// the list view and as the bottom overlay on the map view.  If
  /// [inList] is true the card has vertical margins; otherwise it
  /// appears flush at the bottom of the screen.  [onTapCard] and
  /// [onTapBook] can be provided to handle taps on the card and
  /// booking button respectively.
  Widget _buildSalonPreviewCard(
    BuildContext context,
    SalonLocation salon, {
    bool inList = false,
    VoidCallback? onTapCard,
    VoidCallback? onTapBook,
  }) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    // Build a row of euro icons for the price level.  Each character in
    // the price string corresponds to one euro icon.
    final Widget priceRow = Row(
      children: salon.priceLevel
          .split('')
          .map((c) => const Icon(Icons.euro, size: 16))
          .toList(),
    );
    // Build the star rating using full and half stars.
    final int fullStars = salon.rating.floor();
    final bool hasHalfStar = (salon.rating - fullStars) >= 0.5;
    final List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(const Icon(Icons.star, size: 16, color: Colors.amber));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(const Icon(Icons.star_half, size: 16, color: Colors.amber));
      } else {
        stars.add(Icon(Icons.star_border,
            size: 16,
            color: brightness == Brightness.dark
                ? Colors.white70
                : Colors.black38));
      }
    }
    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, inList ? 8 : 0, 16, inList ? 8 : 16),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? Colors.black.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder for salon image.  In a real app this
                // would display the salon's cover image.
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.black12,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salon.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          priceRow,
                          const SizedBox(width: 8),
                          Row(children: stars),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Placeholder subtitle.  Could be replaced with
                      // salon.subtitle if available.
                      Text(
                        'Subtitle',
                        style: TextStyle(
                          fontSize: 14,
                          color: brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Placeholder description.  Truncate to two lines.
            Text(
              'Beschreibung des Salons. ',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTapBook ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Salon "${salon.name}" ausgewählt (Demo)')),
                      );
                    },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accent),
                ),
                child: Text('Buchen', style: TextStyle(color: accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;
    final Color accent = theme.colorScheme.secondary;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Map or list view
            Positioned.fill(
              child: _showList
                  ? _buildListView(theme)
                  : _buildMapView(theme),
            ),
            // Top overlay containing the toggle buttons, search bar and filter
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton(
                          label: 'Map',
                          icon: Icons.map,
                          active: !_showList,
                          onTap: () {
                            setState(() {
                              _showList = false;
                            });
                          },
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                        _buildToggleButton(
                          label: 'List',
                          icon: Icons.list,
                          active: _showList,
                          onTap: () {
                            setState(() {
                              _showList = true;
                              _selectedSalon = null;
                            });
                          },
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildSearchBar(theme)),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                            backgroundColor: brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.6)
                                : Colors.white.withOpacity(0.6),
                            elevation: 0,
                            side: BorderSide(
                              color: brightness == Brightness.dark
                                  ? Colors.white54
                                  : Colors.black54,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: _openFilterSheet,
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bottom card overlay when a salon is selected and map view is active
            if (_selectedSalon != null && !_showList)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildSalonPreviewCard(
                  context,
                  _selectedSalon!,
                  onTapCard: () => _openSalonDetail(_selectedSalon!),
                  onTapBook: () => _startBooking(_selectedSalon!),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: accent,
        unselectedItemColor: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
        backgroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
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
              // Navigate back to home.  Remove all routes to avoid stacking.
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
                // Navigate to a placeholder CRM page; supply id as an example.
                Navigator.of(context).pushNamed('/crm/customer', arguments: {'id': 1});
              }
              break;
          }
        },
      ),
    );
  }
}