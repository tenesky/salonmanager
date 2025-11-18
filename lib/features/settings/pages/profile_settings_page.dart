import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../services/auth_service.dart';
import '../../../services/db_service.dart';

/// Displays the settings page for a normal user.  This page shows the
/// user's avatar, name and handle at the top followed by a list of
/// configurable settings.  Options include editing personal profile
/// information, logging out, managing notifications and toggling
/// appearance, language and privacy settings.  Tapping each option
/// navigates to the corresponding settings page or performs an action.
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  String _displayName = '';
  String _handle = '';
  String? _photoUrl;
  bool _loading = true;

  /// Picks an image from the device's gallery and updates the
  /// profile photo. The image path is persisted locally via
  /// SharedPreferences under the key `profile.photoPath` so that the
  /// selected avatar is retained across app launches. Errors are
  /// ignored silently.
  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile.photoPath', picked.path);
      if (!mounted) return;
      setState(() {
        _photoUrl = picked.path;
      });
    } catch (_) {
      // silently ignore any errors during image selection
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Loads the current user's display name, handle and avatar.  The
  /// display name is derived from the stored first name (if present) or
  /// inferred from the email address.  The handle is built from the
  /// email's local part.  A photo URL can be loaded from future
  /// extensions (currently unused and left null).
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await DbService.getUserPreferences();
      final firstName = prefs?['first_name'] as String?;
      final email = AuthService.currentUserEmail();
      String name;
      String handle;
      if (firstName != null && firstName.isNotEmpty) {
        // Try to derive a last name from the email's local part
        if (email != null) {
          final local = email.split('@')[0];
          // If the local part contains a dot, use the part after the first dot
          if (local.contains('.')) {
            final parts = local.split('.');
            final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
            if (last.isNotEmpty) {
              name = '${_capitalize(firstName)} ${_capitalize(last)}';
            } else {
              name = _capitalize(firstName);
            }
          } else {
            name = _capitalize(firstName);
          }
        } else {
          name = _capitalize(firstName);
        }
      } else if (email != null) {
        final local = email.split('@')[0];
        // Replace dots and underscores with spaces and capitalise
        final cleaned = local.replaceAll(RegExp(r'[._]'), ' ');
        name = cleaned
            .split(' ')
            .map((word) => word.isEmpty ? '' : _capitalize(word))
            .join(' ');
      } else {
        name = 'User';
      }
      // Build the handle from the email local part
      if (email != null) {
        final local = email.split('@')[0];
        handle = '@$local';
      } else {
        handle = '';
      }
      if (mounted) {
        // Attempt to load a locally stored profile photo path from
        // SharedPreferences. If present, this path will be used as
        // the avatar. Otherwise, _photoUrl remains null.
        final SharedPreferences localPrefs = await SharedPreferences.getInstance();
        final String? localPhotoPath = localPrefs.getString('profile.photoPath');
        setState(() {
          _displayName = name;
          _handle = handle;
          _photoUrl = localPhotoPath;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        // Even on error, attempt to load a locally stored profile photo
        // from SharedPreferences so that the user still sees their chosen
        // avatar when database access fails.
        final SharedPreferences localPrefs = await SharedPreferences.getInstance();
        final String? localPhotoPath = localPrefs.getString('profile.photoPath');
        setState(() {
          _displayName = 'User';
          _handle = '';
          _photoUrl = localPhotoPath;
          _loading = false;
        });
      }
    }
  }

  /// Capitalises the first letter of [word] and lowercases the rest.
  String _capitalize(String word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        children: [
          // Profile header with avatar, name and handle
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Display either a network image or a local file as the avatar.
                    () {
                      ImageProvider? provider;
                      if (_photoUrl != null && _photoUrl!.isNotEmpty) {
                        if (_photoUrl!.startsWith('http')) {
                          provider = NetworkImage(_photoUrl!);
                        } else {
                          provider = FileImage(File(_photoUrl!));
                        }
                      }
                      return CircleAvatar(
                        radius: 40,
                        backgroundColor: brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.black12,
                        backgroundImage: provider,
                        child: provider == null
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: brightness == Brightness.dark
                                    ? Colors.white54
                                    : Colors.black54,
                              )
                            : null,
                      );
                    }(),
                    // Edit icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickProfileImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _displayName,
                  style: theme.textTheme.titleMedium,
                ),
                if (_handle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _handle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // List of settings options
          _buildListTile(
            context,
            icon: Icons.person,
            title: 'Profil‑Informationen',
            onTap: () {
              Navigator.pushNamed(context, '/profile/preferences');
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            context,
            icon: Icons.logout,
            title: 'Ausloggen',
            onTap: () {
              // Show confirmation dialog before logging out
              showDialog(
                context: context,
                builder: (ctx) {
                  final theme = Theme.of(context);
                  final accent = theme.colorScheme.secondary;
                  return AlertDialog(
                    title: const Text('Log out'),
                    content: const Text(
                        "Are you sure you want to log out? You'll need to login again to use the app."),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    actionsAlignment: MainAxisAlignment.spaceBetween,
                    actions: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accent),
                          foregroundColor: accent,
                          minimumSize: const Size(100, 40),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: theme.brightness == Brightness.dark
                              ? Colors.black
                              : Colors.black,
                          minimumSize: const Size(100, 40),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await AuthService.logout();
                          if (!mounted) return;
                          // After logging out, direct the user to the modern login page
                          // rather than the old welcome page. The '/login' route displays
                          // the new login screen introduced after the splash page.
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', (route) => false);
                        },
                        child: const Text('Log out'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.pushNamed(context, '/settings/notifications');
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            context,
            icon: Icons.color_lens,
            title: 'Appearance',
            onTap: () {
              Navigator.pushNamed(context, '/settings/appearance');
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            context,
            icon: Icons.language,
            title: 'Language',
            onTap: () {
              Navigator.pushNamed(context, '/settings/language');
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            context,
            icon: Icons.lock,
            title: 'Privacy & Security',
            onTap: () {
              Navigator.pushNamed(context, '/settings/privacy');
            },
          ),
        ],
      ),
      // Include a persistent bottom navigation bar across the app.
      bottomNavigationBar: _buildBottomNav(context, currentIndex: 4),
    );
  }

  /// Builds a bottom navigation bar similar to the home page.  The
  /// [currentIndex] parameter determines which item is highlighted.
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
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
            break;
          case 1:
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/gallery', (route) => false);
            break;
          case 2:
            Navigator.of(context)
                .pushNamed('/booking/select-salon');
            break;
          case 3:
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/profile/bookings');
            }
            break;
          case 4:
            // Already on profile; do nothing
            break;
        }
      },
    );
  }

  /// Builds a list tile with a leading icon, title and trailing arrow.
  Widget _buildListTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return ListTile(
      leading: Icon(icon,
          color: brightness == Brightness.dark
              ? Colors.white
              : Colors.black),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}