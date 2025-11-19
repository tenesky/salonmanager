import 'package:flutter/material.dart';
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';

/// A page showing the current user's liked images and their own posts.
///
/// This page expects two lists to be provided via the route
/// `arguments`: `likedImages` and `myImages`, each being a List of
/// Map<String, dynamic>. If not provided, the lists default to empty.
/// The page uses a [TabBar] to switch between the liked images and
/// the user's own images. Each image is shown in a grid similar to
/// the main gallery page. The user can tap to open the detail page or
/// unlike/delete directly.
class GalleryProfilePage extends StatefulWidget {
  const GalleryProfilePage({Key? key}) : super(key: key);

  @override
  State<GalleryProfilePage> createState() => _GalleryProfilePageState();
}

class _GalleryProfilePageState extends State<GalleryProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _likedImages = [];
  List<Map<String, dynamic>> _myImages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load arguments after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _likedImages = (args['likedImages'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          _myImages = (args['myImages'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _unlikeImage(dynamic imageId) async {
    try {
      await DbService.unlikeGalleryImage(imageId);
      setState(() {
        _likedImages.removeWhere((img) => img['id'] == imageId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Entfernen des Likes: \$e')),
      );
    }
  }

  /// Deletes a gallery image owned by the current user. Accepts a dynamic
  /// imageId because IDs may be integers (for sample assets) or uuid strings
  /// for real Supabase entries. The duplicated signature has been removed.
  Future<void> _deleteImage(dynamic imageId) async {
    try {
      await DbService.deleteGalleryImage(imageId);
      setState(() {
        _myImages.removeWhere((img) => img['id'] == imageId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen: \$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Galerie'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Likes'),
            Tab(text: 'Meine Bilder'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImageGrid(_likedImages, isLikedTab: true),
          _buildImageGrid(_myImages, isMyImages: true),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 4,
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
                Navigator.of(context)
                    .pushNamed('/profile/bookings');
              }
              break;
            case 4:
              // Navigate to general profile settings
              if (!AuthService.isLoggedIn()) {
                Navigator.of(context).pushNamed('/login');
              } else {
                Navigator.of(context).pushNamed('/settings/profile');
              }
              break;
          }
        },
      ),
    );
  }

  Widget _buildImageGrid(List<Map<String, dynamic>> images,
      {bool isLikedTab = false, bool isMyImages = false}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: images.isEmpty
          ? const Center(child: Text('Keine Bilder vorhanden.'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final img = images[index];
                final bool liked = _likedImages
                    .any((element) => element['id'] == img['id']);
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/gallery/detail',
                      arguments: img,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: img.containsKey('asset')
                              ? Image.asset(
                                  img['asset'] as String,
                                  fit: BoxFit.cover,
                                )
                              : img.containsKey('url')
                                  ? Image.network(
                                      img['url'] as String,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey.shade300,
                                    ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: isLikedTab
                              ? IconButton(
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () => _unlikeImage(img['id']),
                                )
                              : isMyImages
                                  ? IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteImage(img['id']),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}