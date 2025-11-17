import 'package:flutter/material.dart';
import 'package:salonmanager/common/themed_background.dart';
import 'package:salonmanager/services/auth_service.dart';

/// A detail page for customers to view comprehensive information about a
/// salon.  When navigating to this page supply a `Map<String, dynamic>`
/// via the `arguments` containing salon details such as `name`,
/// `description`, `opening_hours`, `contact`, `price_level`, `rating` and
/// `image_url`.  All values are optional; sensible defaults will be
/// displayed if information is missing.  The page includes a large
/// header image with a back button, salon information and a simple
/// bottom navigation bar so users can continue exploring other parts of
/// the app.  This widget is intentionally lightweight to avoid
/// introducing any compile‑time errors when the underlying schema
/// evolves.
class CustomerSalonDetailPage extends StatelessWidget {
  final Map<String, dynamic> salon;

  const CustomerSalonDetailPage({Key? key, required this.salon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name = salon['name']?.toString() ?? 'Salon';
    final String description = salon['description']?.toString() ?? '';
    final String openingHours = salon['opening_hours']?.toString() ?? '';
    final String contact = salon['contact']?.toString() ?? '';
    final String priceLevel = salon['price_level']?.toString() ?? '';
    final double rating = () {
      final dynamic r = salon['rating'];
      if (r is num) return r.toDouble();
      return 0.0;
    }();
    final String imageUrl = salon['image_url']?.toString() ?? '';
    // Load the logo image if provided. Accept various keys for flexibility.
    final String logoImage =
        salon['logo_image']?.toString() ??
        salon['logoImage']?.toString() ??
        salon['logo_url']?.toString() ??
        '';

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Top image with back arrow overlay
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(
                                Icons.photo,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: theme.colorScheme.onBackground,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              // Information sections
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display the salon name, rating and price alongside a small logo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            backgroundImage: logoImage.isNotEmpty
                                ? (logoImage.startsWith('http')
                                    ? NetworkImage(logoImage)
                                    : AssetImage(logoImage) as ImageProvider)
                                : null,
                            child: logoImage.isEmpty
                                ? const Icon(Icons.image, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (index) {
                                    if (rating >= index + 1) {
                                      return const Icon(Icons.star,
                                          size: 16, color: Colors.amber);
                                    } else if (rating > index) {
                                      return const Icon(Icons.star_half,
                                          size: 16, color: Colors.amber);
                                    } else {
                                      return const Icon(Icons.star_border,
                                          size: 16, color: Colors.amber);
                                    }
                                  }),
                                ),
                                const SizedBox(height: 4),
                                // Display the price level as a row of euro icons. Each
                                // character in the priceLevel string results in one
                                // euro symbol. If the string is empty the row will be
                                // empty.
                                Row(
                                  children: priceLevel.isNotEmpty
                                      ? priceLevel
                                          .split('')
                                          .map((_) => const Icon(
                                                Icons.euro,
                                                size: 16,
                                                color: Colors.grey,
                                              ))
                                          .toList()
                                      : <Widget>[],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (description.isNotEmpty) ...[
                        Text(
                          'Beschreibung',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(description, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],
                      if (openingHours.isNotEmpty) ...[
                        Text(
                          'Öffnungszeiten',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(openingHours, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],
                      if (contact.isNotEmpty) ...[
                        Text(
                          'Kontaktdaten',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(contact, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Bewertung',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('Noch keine Bewertungen', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      // Button to launch the booking wizard
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to the booking wizard. If the user is
                            // not logged in, redirect to login first.
                            if (!AuthService.isLoggedIn()) {
                              Navigator.of(context).pushNamed('/login');
                            } else {
                              Navigator.of(context).pushNamed('/booking/select-salon');
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Termin buchen'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BottomNav(currentIndex: 0),
      ),
    );
  }
}

/// Private helper widget replicating the bottom navigation bar used
/// across the customer sections of the app.  The [currentIndex]
/// determines which tab is highlighted.  When tapping an item the
/// appropriate route is pushed.  This helper avoids repeating the
/// boilerplate in every page.
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({Key? key, required this.currentIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    final brightness = theme.brightness;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: accent,
      unselectedItemColor:
          brightness == Brightness.dark ? Colors.white70 : Colors.black54,
      backgroundColor:
          brightness == Brightness.dark ? Colors.black : Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Galerie'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Buchen'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Termine'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context).pushNamed('/home');
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
              Navigator.of(context).pushNamed('/settings/profile');
            }
            break;
        }
      },
    );
  }
}