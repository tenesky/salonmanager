import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/themed_background.dart';
import '../../../services/db_service.dart';

/// A simple public gallery page displaying hair style images in a
/// responsive grid. Users can filter by hair length, style and
/// colour using chips above the grid. Tapping a tile opens a detail
/// page with a larger preview, description and a button to start a
/// booking. Images are currently loaded from the local assets as
/// placeholders; later they can be fetched from Supabase via the
/// `gallery_images` table defined in the schema.
class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _images = [];
  Set<String> _likedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
    });
    try {
      final images = await DbService.getGalleryImages(
          searchQuery: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim());
      final liked = await DbService.getLikedImageIdsForCurrentUser();
      if (mounted) {
        setState(() {
          _images = images;
          _likedIds = liked.toSet();
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

  Future<void> _toggleLike(String imageId) async {
    final currentlyLiked = _likedIds.contains(imageId);
    if (currentlyLiked) {
      await DbService.unlikeGalleryImage(imageId);
      _likedIds.remove(imageId);
    } else {
      await DbService.likeGalleryImage(imageId);
      _likedIds.add(imageId);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final fileName = picked.name;
    // Ask for description via dialog
    final descriptionController = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bildbeschreibung'),
          content: TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Beschreibung eingeben'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, descriptionController.text),
              child: const Text('Hochladen'),
            ),
          ],
        );
      },
    );
    if (description == null) return;
    try {
      final url = await DbService.uploadGalleryImage(bytes, fileName);
      await DbService.createGalleryImage(url: url, description: description);
      await _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Hochladen: $e')),
      );
    }
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Suche',
                              hintStyle: TextStyle(
                                color: brightness == Brightness.dark
                                    ? Colors.white54
                                    : Colors.black45,
                              ),
                              border: InputBorder.none,
                              icon: Icon(
                                Icons.search,
                                color: brightness == Brightness.dark
                                    ? Colors.white54
                                    : Colors.black45,
                              ),
                            ),
                            onSubmitted: (_) => _fetchData(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          // TODO: implement filter options if desired
                        },
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        itemCount: _images.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3 / 4,
                        ),
                        itemBuilder: (context, index) {
                          final img = _images[index];
                          final id = img['id'].toString();
                          final url = img['url'] as String;
                          final desc = img['description'] as String? ?? '';
                          final liked = _likedIds.contains(id);
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/gallery/detail',
                                arguments: {
                                  'id': id,
                                  'url': url,
                                  'description': desc,
                                },
                              ).then((_) => _fetchData());
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, _) => Container(
                                        color: Colors.grey[300],
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                    ),
                                  ),
                                  // Heart icon
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24.0),
                                      onTap: () async {
                                        await _toggleLike(id);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4.0),
                                        decoration: BoxDecoration(
                                          color: brightness == Brightness.dark
                                              ? Colors.black.withOpacity(0.4)
                                              : Colors.white.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          liked ? Icons.favorite : Icons.favorite_border,
                                          size: 20,
                                          color: liked
                                              ? theme.colorScheme.secondary
                                              : (brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _pickAndUploadImage,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'profile',
            mini: true,
            onPressed: () {
              Navigator.pushNamed(context, '/gallery/profile');
            },
            child: const Icon(Icons.person),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              break;
            case 1:
              // Already on gallery page
              break;
            case 2:
              Navigator.pushNamedAndRemoveUntil(
                  context, '/booking/select-salon', (route) => false);
              break;
            case 3:
              Navigator.pushNamedAndRemoveUntil(
                  context, '/profile/bookings', (route) => false);
              break;
            case 4:
              Navigator.pushNamedAndRemoveUntil(
                  context, '/profile', (route) => false);
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
        unselectedItemColor: brightness == Brightness.dark
            ? Colors.white70
            : Colors.black54,
      ),
    );
  }
}