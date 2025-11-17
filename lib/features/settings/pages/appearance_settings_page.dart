import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

/// Placeholder page for appearance settings.  In a full implementation
/// this screen would allow users to toggle dark mode, choose accent
/// colours and customise the theme.  For now it simply displays a
/// message indicating that the feature is under development.
class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: const Center(
        child: Text('Appearance settings will be available soon.'),
      ),
      // Persistent bottom navigation bar with Profile selected
      bottomNavigationBar: _buildBottomNav(context, currentIndex: 4),
    );
  }

  /// Builds a bottom navigation bar with the given [currentIndex].  It
  /// mirrors the navigation bar used on other pages so that the
  /// user can switch between core sections.  The Profile index is
  /// highlighted on settings pages.
  Widget _buildBottomNav(BuildContext context, {required int currentIndex}) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
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
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Buchen'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Termine'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
            break;
          case 1:
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/gallery', (route) => false);
            break;
          case 2:
            Navigator.of(context).pushNamed('/booking/select-salon');
            break;
          case 3:
            // If not logged in redirect to login; else to bookings list
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/profile/bookings');
            }
            break;
          case 4:
            // Navigate back to main profile settings page
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/settings/profile', (route) => false);
            break;
        }
      },
    );
  }
}