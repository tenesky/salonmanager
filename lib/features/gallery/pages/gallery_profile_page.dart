import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../common/themed_background.dart';
import '../../../services/db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Displays the current user's gallery contributions and liked images.
/// Users can remove likes from liked images and edit or delete their own
/// posts. This page is navigated to from the gallery screen via the
/// profile button. It fetches data from Supabase when first opened
/// and refreshes automatically when returning from edit/delete flows.
class GalleryProfilePage extends StatefulWidget {
  const GalleryProfilePage({Key? key}) : super(key: key);

  @override
  State<GalleryProfilePage> createState() => _GalleryProfilePageState();
}

class _GalleryProfilePageState extends State<GalleryProfilePage> {
  List<Map<String, dynamic>> _liked = [];
  List<Map<String, dynamic>> _mine = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    try {
      final liked = await DbService.getLikedGalleryImages();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final mine = await DbService.getGalleryImagesByUser(userId);
      if (mounted) {
        setState(() {
          _liked = liked;
          _mine = mine;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleLike(String imageId, bool liked) async {
    if (liked) {
      await DbService.unlikeGalleryImage(imageId);
    } else {
      await DbService.likeGalleryImage(imageId);
    }
    await _loadData();
  }

  Future<void> _deleteImage(String id) async {
    await DbService.deleteGalleryImage(id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Scaffold(
      body: ThemedBackground(
        child: Container(
          color: brightness == Brightness.dark
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.4),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Meine Galerie',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // My posts section
                          if (_mine.isNotEmpty) ...[
                            Text(
                              'Meine Beiträge',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildImagesList(_mine, own: true),
                            const SizedBox(height: 24),
                          ],
                          // Liked section
                          if (_liked.isNotEmpty) ...[
                            Text(
                              'Gelikt',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildImagesList(_liked, own: false),
                          ],
                          if (_mine.isEmpty && _liked.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 32.0),
                              child: Center(
                                child: Text(
                                  'Keine Bilder vorhanden.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: brightness == Brightness.dark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
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
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildImagesList(List<Map<String, dynamic>> images, {required bool own}) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final img = images[index];
        final imageId = img['id'].toString();
        final url = img['url'] as String;
        final desc = img['description'] as String? ?? '';
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.8),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc.isEmpty ? 'Kein Titel' : desc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Delete/edit for own images or unlike for liked images
                    Row(
                      children: [
                        if (own) ...[
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Bearbeiten',
                            onPressed: () async {
                              // show dialog for editing description
                              final controller = TextEditingController(text: desc);
                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Bildbeschreibung bearbeiten'),
                                    content: TextField(
                                      controller: controller,
                                      maxLines: 3,
                                      decoration: const InputDecoration(hintText: 'Beschreibung'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Abbrechen'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, controller.text),
                                        child: const Text('Speichern'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result != null) {
                                await DbService.updateGalleryImage(id: imageId, description: result);
                                await _loadData();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Löschen',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Bild löschen?'),
                                    content: const Text(
                                        'Möchten Sie dieses Bild wirklich dauerhaft löschen?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Abbrechen'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Löschen'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirm == true) {
                                await _deleteImage(imageId);
                              }
                            },
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.favorite),
                            color: theme.colorScheme.secondary,
                            onPressed: () async {
                              await _toggleLike(imageId, true);
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: 1, // Gallery tab highlighted
      onTap: (index) {
        // Navigate between tabs. Use the same logic as Home and Map pages.
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            break;
          case 1:
            // stay on gallery profile page; maybe navigate back to gallery grid
            Navigator.pushNamedAndRemoveUntil(context, '/gallery', (route) => false);
            break;
          case 2:
            Navigator.pushNamedAndRemoveUntil(
                context, '/booking/select-salon', (route) => false);
            break;
          case 3:
            Navigator.pushNamedAndRemoveUntil(context, '/profile/bookings', (route) => false);
            break;
          case 4:
            Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_library),
          label: 'Galerie',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Buchen',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Termine',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
      selectedItemColor: theme.colorScheme.secondary,
      unselectedItemColor: theme.brightness == Brightness.dark
          ? Colors.white70
          : Colors.black54,
    );
  }
}