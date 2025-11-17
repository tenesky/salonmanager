import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/db_service.dart';
import '../../../common/themed_background.dart';

/// Detail page for a gallery item. Displays a larger image with
/// description and a button to start a booking. Expects the image
/// data (id, asset, description, etc.) to be passed via
/// [ModalRoute.settings.arguments] as a Map<String, dynamic>.
class GalleryDetailPage extends StatefulWidget {
  const GalleryDetailPage({Key? key}) : super(key: key);

  @override
  State<GalleryDetailPage> createState() => _GalleryDetailPageState();
}

class _GalleryDetailPageState extends State<GalleryDetailPage> {
  String? _id;
  String? _url;
  String? _description;
  bool _liked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _id = args['id']?.toString();
      _url = args['url'] as String?;
      _description = args['description'] as String?;
      _initLiked();
    }
  }

  Future<void> _initLiked() async {
    if (_id == null) return;
    final likes = await DbService.getLikedImageIdsForCurrentUser();
    if (mounted) {
      setState(() {
        _liked = likes.contains(_id);
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_id == null) return;
    if (_liked) {
      await DbService.unlikeGalleryImage(_id!);
    } else {
      await DbService.likeGalleryImage(_id!);
    }
    if (mounted) {
      setState(() {
        _liked = !_liked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    if (_url == null) {
      return const Scaffold(
        body: Center(child: Text('Keine Bildinformationen verfügbar.')),
      );
    }
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
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: _url!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24.0),
                                  onTap: _toggleLike,
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: brightness == Brightness.dark
                                          ? Colors.black.withOpacity(0.4)
                                          : Colors.white.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _liked ? Icons.favorite : Icons.favorite_border,
                                      size: 28,
                                      color: _liked
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
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _description ?? '',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/booking/select-salon');
                                  },
                                  child: const Text('Termin buchen'),
                                ),
                              ),
                            ],
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              break;
            case 1:
              Navigator.pushNamedAndRemoveUntil(context, '/gallery', (route) => false);
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
        unselectedItemColor: brightness == Brightness.dark
            ? Colors.white70
            : Colors.black54,
      ),
    );
  }
}