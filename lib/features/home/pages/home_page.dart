import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/themed_background.dart';
import '../../../services/auth_service.dart';
import '../../../services/db_service.dart';
import '../../salon/models/salon.dart';

/// Home page for customers. This screen shows a simple search field,
/// a placeholder map section and a few recommended salons. It serves
/// as the landing page after login and does not require backend
/// interaction. Navigation to the full salon list is provided at the
/// bottom. A bottom navigation bar allows quick access to the
/// customer profile.
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State for [HomePage]. This class retrieves the user's current
/// location (if permission is granted) and displays a small map
/// preview directly on the home screen. Tapping the map preview
/// navigates to the full interactive map. The bottom buttons use
/// custom styles to ensure the text remains legible in dark mode. A
/// bottom navigation bar is used to navigate to the profile page.
class _HomePageState extends State<HomePage> {
  LatLng? _userLocation;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _salons = [];
  List<Marker> _salonMarkers = [];
  String? _firstName;
  bool _showMap = true;

  /// Builds a toggle button used in the map/list switch. The active
  /// button is filled with the accent colour; inactive buttons are
  /// transparent with coloured text and icon.
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

  @override
  void initState() {
    super.initState();
    _loadFirstName();
    _loadUserLocation();
    _loadSalons(); // load initial salon list
  }

  /// Loads the first name from shared preferences to greet the user on the
  /// home page. If no value is stored the greeting will omit the name.
  Future<void> _loadFirstName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('profile.firstName');
      if (mounted) {
        setState(() {
          _firstName = name;
        });
      }
    } catch (_) {
      // ignore errors silently
    }
  }

  /// Requests location permissions and obtains the current position
  /// using the [Geolocator] plugin. If permission is denied or an
  /// error occurs, the location remains null and the map preview
  /// defaults to a neutral center.
  Future<void> _loadUserLocation() async {
    try {
      // Request permission if not already granted
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
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Ignore errors silently; location remains null
    }
  }

  /// Loads salons from Supabase and updates the list and markers.
  Future<void> _loadSalons() async {
    try {
      final salons = await DbService.getSalons(
        searchQuery: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      // Build markers for the mini map
      final List<Marker> markers = [];
      for (final s in salons) {
        final lat = s['latitude'] as double?;
        final lng = s['longitude'] as double?;
        if (lat != null && lng != null) {
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_pin,
                color: Colors.orange,
                size: 32,
              ),
            ),
          );
        }
      }
      setState(() {
        _salons = salons;
        _salonMarkers = markers;
      });
    } catch (_) {
      // ignore errors silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return Scaffold(
      // Remove the traditional app bar; build the page inside SafeArea.
      body: ThemedBackground(
        child: Container(
          color: brightness == Brightness.dark
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.4),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    _firstName != null && _firstName!.isNotEmpty
                        ? 'Hallo\n${_firstName!}'
                        : 'Hallo',
                    style: TextStyle(
                      color: brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Salons in deiner Nähe',
                    style: TextStyle(
                      color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                      ),
                      prefixIcon: Icon(Icons.search,
                          color:
                              brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (_) => _loadSalons(),
                  ),
                  const SizedBox(height: 16),
                  // Map or list toggle section
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Show either map preview or placeholder list depending on toggle
                        Positioned.fill(
                          child: _showMap
                              ? FlutterMap(
                                  options: MapOptions(
                                    center: _userLocation ??
                                        const LatLng(48.137154, 11.576124),
                                    zoom: 13.0,
                                    interactiveFlags:
                                        InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                    if (_salonMarkers.isNotEmpty)
                                      MarkerLayer(markers: _salonMarkers),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    'List view not implemented',
                                    style: TextStyle(
                                      color: brightness == Brightness.dark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                        ),
                        if (_userLocation == null)
                          const Center(child: CircularProgressIndicator()),
                        // Toggle buttons overlay
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: brightness == Brightness.dark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.6),
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
                        ),
                        // Overlay to navigate to full map on tap (only when showMap)
                        if (_showMap)
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamed('/salons/map');
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Salon list items (top 3)
                  Column(
                    children: [
                      if (_salons.isEmpty)
                        Text(
                          'Keine Salons gefunden',
                          style: TextStyle(
                            color: brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      for (var i = 0;
                          i < (_salons.length < 3 ? _salons.length : 3);
                          i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _HomeSalonCard(
                            name: _salons[i]['name'] as String? ?? 'Salon',
                            onTap: () {
                              final salon = Salon(
                                name: _salons[i]['name'] as String? ?? '',
                                coverImage: 'assets/background_dark.png',
                                logoImage: 'assets/logo_full.png',
                                address: 'Adresse nicht verfügbar',
                                openingHours: '',
                                phone: '',
                              );
                              Navigator.pushNamed(context, '/salon-detail', arguments: salon);
                            },
                          ),
                        ),
                    ],
                  ),
                  // Optionally add spacing at bottom to allow for bottom nav
                  const SizedBox(height: 80),
                ],
              ),
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
              // Stay on home
              break;
            case 1:
              Navigator.of(context).pushNamed('/gallery');
              break;
            case 2:
              Navigator.of(context).pushNamed('/booking/select-salon');
              break;
            case 3:
              // Show appointments
              if (!AuthService.isLoggedIn()) {
                Navigator.of(context).pushNamed('/login');
              } else {
                Navigator.of(context).pushNamed('/profile/bookings');
              }
              break;
            case 4:
              // Profile
              if (!AuthService.isLoggedIn()) {
                Navigator.of(context).pushNamed('/login');
              } else {
                // Use CRM profile as placeholder; in a real app this would be a user profile page
                Navigator.of(context).pushNamed('/crm/customer', arguments: {'id': 1});
              }
              break;
          }
        },
      ),
    );
  }
}

/// A simple card widget representing a salon. In a production app this
/// would likely be a separate file and include an image and more
/// detailed styling.
class _SalonCard extends StatelessWidget {
  final String name;
  final String distance;
  final double rating;
  final String priceLevel;
  final VoidCallback? onTap;

  const _SalonCard({
    required this.name,
    required this.distance,
    required this.rating,
    required this.priceLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.store, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Row(
          children: [
            Icon(Icons.star, size: 16, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text(rating.toString()),
            const SizedBox(width: 8),
            const Icon(Icons.location_on, size: 16),
            const SizedBox(width: 4),
            Text(distance),
            const SizedBox(width: 8),
            const Icon(Icons.attach_money, size: 16),
            const SizedBox(width: 2),
            Text(priceLevel),
          ],
        ),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Salon "$name" ausgewählt (Demo)')),
            );
          }
        },
      ),
    );
  }
}

/// A card used on the home page to display a salon in the compact list.
/// It follows the design shown in the provided mockup: a rounded
/// container with a yellow square on the left, the salon name in the
/// middle and a bordered button on the right. When tapped, both
/// the row and the button trigger the same [onTap] callback.
class _HomeSalonCard extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _HomeSalonCard({
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
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
              // Left yellow icon square
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.image,
                  color: brightness == Brightness.dark ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              // Salon name
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Action button
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                child: const Text('Button'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
