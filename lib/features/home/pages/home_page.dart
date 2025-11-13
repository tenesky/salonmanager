import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadSalons(); // load initial salon list
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Salons suchen...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (_) {
                  _loadSalons();
                },
              ),
              const SizedBox(height: 16),
              // Map preview. Displays a miniature map centered on the
              // user's location if available. Tapping the preview
              // navigates to the full map page.
              Container(
                height: 200,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        center: _userLocation ?? const LatLng(48.137154, 11.576124),
                        zoom: 13.0,
                        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
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
                        // markers for salons
                        if (_salonMarkers.isNotEmpty)
                          MarkerLayer(markers: _salonMarkers),
                      ],
                    ),
                    // Transparent overlay to capture taps for
                    // navigation to the full map page.
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.0),
                          onTap: () {
                            Navigator.of(context).pushNamed('/salons/map');
                          },
                        ),
                      ),
                    ),
                    // If location is still loading, show a small
                    // progress indicator in the center.
                    if (_userLocation == null)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Empfohlene Salons',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // Dynamic list of recommended salons. Shows up to three salons
              // sorted by rating. If no salons are available, display a
              // message. Each card navigates to the salon detail page.
              Column(
                children: [
                  if (_salons.isEmpty)
                    const Text('Keine Salons gefunden'),
                  for (var i = 0; i < (_salons.length < 3 ? _salons.length : 3); i++) ...[
                    _SalonCard(
                      name: _salons[i]['name'] as String? ?? '',
                      distance: '',
                      rating: (_salons[i]['rating'] as num?)?.toDouble() ?? 0.0,
                      priceLevel: _salons[i]['price_level'] as String? ?? '',
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
                    const SizedBox(height: 12),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.colorScheme.onSurface),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/salon-list');
                  },
                  child: const Text('Alle Salons anzeigen'),
                ),
              ),
              const SizedBox(height: 12),
              // Button to open the user's bookings. This allows customers to
              // review upcoming and past appointments after completing the
              // booking flow.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.colorScheme.onSurface),
                  ),
                  onPressed: () {
                    // Require the user to be authenticated before showing their bookings.
                    // If not logged in, redirect to the login page first. Otherwise
                    // navigate to the bookings list.
                    if (!AuthService.isLoggedIn()) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).pushNamed('/profile/bookings');
                    }
                  },
                  child: const Text('Meine Buchungen'),
                ),
              ),

              const SizedBox(height: 12),
              // Button to open the loyalty overview. This demonstrates the
              // Treue‑Programm page with static points and rewards. In a
              // real implementation the values would be loaded from the
              // salon's loyalty program and the customer's account.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.colorScheme.onSurface),
                  ),
                  onPressed: () {
                    if (!AuthService.isLoggedIn()) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).pushNamed('/loyalty');
                    }
                  },
                  child: const Text('Treue‑Übersicht'),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom navigation bar to navigate to the customer profile. The
      // second item opens the CRM customer profile page for a static
      // user id (1) as a demonstration. In a full implementation
      // this would use the current logged‑in customer's id.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushNamed(
              '/crm/customer',
              arguments: {'id': 1},
            );
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
