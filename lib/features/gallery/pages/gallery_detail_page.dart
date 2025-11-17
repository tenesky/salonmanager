import 'package:flutter/material.dart';
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';

/// Detail page for a gallery item. Displays a larger image with
/// description and allows liking/unliking. Expects the image data
/// (id, asset, url, description, liked) to be passed via
/// [ModalRoute.settings.arguments] as a Map<String, dynamic>.
class GalleryDetailPage extends StatefulWidget {
  const GalleryDetailPage({Key? key}) : super(key: key);

  @override
  State<GalleryDetailPage> createState() => _GalleryDetailPageState();
}

class _GalleryDetailPageState extends State<GalleryDetailPage> {
  late final Map<String, dynamic> _imageData;
  late int _imageId;
  late bool _isLiked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _imageData = args;
      _imageId = args['id'] as int;
      _isLiked = args['liked'] as bool? ?? false;
    }
  }

  Future<void> _toggleLike() async {
    if (!AuthService.isLoggedIn()) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    try {
      if (_isLiked) {
        await DbService.unlikeGalleryImage(_imageId);
      } else {
        await DbService.likeGalleryImage(_imageId);
      }
      setState(() {
        _isLiked = !_isLiked;
      });
    } catch (e) {
      // ignore error
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? asset = _imageData['asset'] as String?;
    final String? url = _imageData['url'] as String?;
    final String description = _imageData['description'] as String? ?? '';
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar with back arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            // Image with like icon overlay
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: asset != null
                        ? Image.asset(
                            asset,
                            fit: BoxFit.cover,
                          )
                        : url != null
                            ? Image.network(
                                url,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade300,
                              ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.amber : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Description area
            Container(
              color: brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.8)
                  : Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                description,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
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
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              break;
            case 1:
              Navigator.of(context).pushNamedAndRemoveUntil('/gallery', (route) => false);
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
                Navigator.of(context).pushNamed('/crm/customer', arguments: {'id': 1});
              }
              break;
          }
        },
      ),
    );
  }
}