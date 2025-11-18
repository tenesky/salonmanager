import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../app.dart';

/// Page for selecting the application language. This screen lists
/// available languages (currently English and German) and updates the
/// app locale when the user taps on a language. The current selection
/// is highlighted with a check icon. The selected locale is persisted
/// using shared preferences by [MyApp.setLocale].
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final currentCode = appState?.locale?.languageCode;
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Deutsch'),
            trailing: currentCode == 'de'
                ? Icon(Icons.check, color: accent)
                : null,
            onTap: () {
              appState?.setLocale(const Locale('de'));
            },
          ),
          ListTile(
            title: const Text('English'),
            trailing: currentCode == 'en'
                ? Icon(Icons.check, color: accent)
                : null,
            onTap: () {
              appState?.setLocale(const Locale('en'));
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, currentIndex: 4),
    );
  }

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
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/profile/bookings');
            }
            break;
          case 4:
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/settings/profile', (route) => false);
            break;
        }
      },
    );
  }
}