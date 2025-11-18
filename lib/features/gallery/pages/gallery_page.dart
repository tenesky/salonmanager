import 'package:flutter/material.dart';
import '../../../services/db_service.dart';
import '../../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  // Gallery images loaded from Supabase. Initially populated with demo
  // images as placeholders until real data is fetched. Each map
  // contains keys: id, asset/url, length, style, colour, description.
  List<Map<String, dynamic>> _images = [
    {
      'id': 1,
      'asset': 'assets/background_light.png',
      'length': 'Kurz',
      'style': 'Modern',
      'colour': 'Blond',
      'description': 'Kurzer moderner Schnitt in blond.'
    },
    {
      'id': 2,
      'asset': 'assets/background_dark.png',
      'length': 'Mittel',
      'style': 'Klassisch',
      'colour': 'Braun',
      'description': 'Mittellanger klassischer Look in braun.'
    },
    {
      'id': 3,
      'asset': 'assets/logo_full.png',
      'length': 'Lang',
      'style': 'Trend',
      'colour': 'Rot',
      'description': 'Langer trendiger Stil in rot.'
    },
    {
      'id': 4,
      'asset': 'assets/logo_symbol.png',
      'length': 'Mittel',
      'style': 'Modern',
      'colour': 'Blond',
      'description': 'Mittellanger moderner Stil in blond.'
    },
  ];

  // Available filter options for length, style and colour.
  final List<String> _lengthOptions = const ['Kurz', 'Mittel', 'Lang'];
  final List<String> _styleOptions = const ['Klassisch', 'Modern', 'Trend'];
  final List<String> _colourOptions = const ['Blond', 'Braun', 'Rot'];

  String? _selectedLength;
  String? _selectedStyle;
  String? _selectedColour;

  // Controller for search input.
  final TextEditingController _searchController = TextEditingController();

  // Track liked image ids.
  final Set<int> _likedImageIds = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
    // Also load the user's liked images once images are fetched.
    // We invoke this after a short delay to ensure Supabase is initialised.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLikedImages();
    });
  }

  /// Loads gallery images from Supabase. If the query fails, the
  /// placeholder images remain. The fetched images will replace the
  /// `_images` list and the UI will be rebuilt.
  Future<void> _loadImages() async {
    try {
      final fetched = await DbService.getGalleryImages();
      setState(() {
        // Merge remote data with placeholder images if remote list is empty.
        if (fetched.isNotEmpty) {
          _images = fetched;
        }
      });
    } catch (_) {
      // In case of an error, keep placeholder images.
    }
  }

  /// Loads the list of image IDs liked by the current user from Supabase.
  /// When the user is not logged in the liked set remains empty.
  Future<void> _loadLikedImages() async {
    if (!AuthService.isLoggedIn()) {
      return;
    }
    try {
      final List<int> ids = await DbService.getLikedGalleryImageIds();
      setState(() {
        _likedImageIds
          ..clear()
          ..addAll(ids);
      });
    } catch (_) {
      // Ignore errors; keep the current liked set.
    }
  }

  /// Returns the list of images matching the current filter settings.
  List<Map<String, dynamic>> get _filteredImages {
    final String query = _searchController.text.trim().toLowerCase();
    return _images.where((img) {
      final bool lengthOk = _selectedLength == null || img['length'] == _selectedLength;
      final bool styleOk = _selectedStyle == null || img['style'] == _selectedStyle;
      final bool colourOk = _selectedColour == null || img['colour'] == _selectedColour;
      final bool matchesSearch = query.isEmpty ||
          (img['description']?.toString().toLowerCase().contains(query) ?? false) ||
          (img['length']?.toString().toLowerCase().contains(query) ?? false) ||
          (img['style']?.toString().toLowerCase().contains(query) ?? false) ||
          (img['colour']?.toString().toLowerCase().contains(query) ?? false);
      return lengthOk && styleOk && colourOk && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _openFilterSheet,
                          child: Row(
                            children: const [
                              Icon(Icons.filter_list, size: 20),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Hinted search text',
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _filteredImages.length,
                      itemBuilder: (context, index) {
                        final img = _filteredImages[index];
                        final bool liked = _likedImageIds.contains(img['id'] as int);
                        return GestureDetector(
                          onTap: () {
                            // Pass the liked status along with the image data
                            final Map<String, dynamic> args = Map<String, dynamic>.from(img);
                            args['liked'] = liked;
                            Navigator.pushNamed(
                              context,
                              '/gallery/detail',
                              arguments: args,
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: img.containsKey('asset') && img['asset'] != null
                                      ? Image.asset(
                                          img['asset'] as String,
                                          fit: BoxFit.cover,
                                        )
                                      : img.containsKey('url') && img['url'] != null
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
                                  // Use IconButton instead of GestureDetector to ensure the
                                  // like button is tappable even when nested inside another
                                  // GestureDetector. Setting zero padding and minimal
                                  // constraints prevents the button from expanding its size.
                                  child: IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      liked ? Icons.favorite : Icons.favorite_border,
                                      color: liked ? Colors.amber : Colors.grey,
                                    ),
                                    onPressed: () => _toggleLike(img['id'] as int),
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
            Positioned(
              bottom: 96,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'gallery_add',
                backgroundColor: brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                onPressed: _openUploadPage,
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: _openProfilePage,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.black),
                ),
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
      ),
    );
  }

  Future<void> _toggleLike(int imageId) async {
    final bool isLiked = _likedImageIds.contains(imageId);
    if (!AuthService.isLoggedIn()) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    try {
      if (isLiked) {
        await DbService.unlikeGalleryImage(imageId);
        _likedImageIds.remove(imageId);
      } else {
        await DbService.likeGalleryImage(imageId);
        _likedImageIds.add(imageId);
      }
      setState(() {});
    } catch (_) {}
  }

  void _openFilterSheet() {
    String? tempLength = _selectedLength;
    String? tempStyle = _selectedStyle;
    String? tempColour = _selectedColour;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Länge'),
                    const SizedBox(height: 4),
                    DropdownButton<String?>(
                      isExpanded: true,
                      value: tempLength,
                      hint: const Text('Alle'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Alle'),
                        ),
                        ..._lengthOptions.map((length) => DropdownMenuItem<String?>(
                              value: length,
                              child: Text(length),
                            )),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempLength = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Stil'),
                    const SizedBox(height: 4),
                    DropdownButton<String?>(
                      isExpanded: true,
                      value: tempStyle,
                      hint: const Text('Alle'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Alle'),
                        ),
                        ..._styleOptions.map((style) => DropdownMenuItem<String?>(
                              value: style,
                              child: Text(style),
                            )),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempStyle = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Farbe'),
                    const SizedBox(height: 4),
                    DropdownButton<String?>(
                      isExpanded: true,
                      value: tempColour,
                      hint: const Text('Alle'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Alle'),
                        ),
                        ..._colourOptions.map((colour) => DropdownMenuItem<String?>(
                              value: colour,
                              child: Text(colour),
                            )),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempColour = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempLength = null;
                              tempStyle = null;
                              tempColour = null;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedLength = tempLength;
                              _selectedStyle = tempStyle;
                              _selectedColour = tempColour;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Anwenden'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openUploadPage() {
    Navigator.of(context).pushNamed('/gallery/upload');
  }

  Future<void> _openProfilePage() async {
    if (!AuthService.isLoggedIn()) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    List<Map<String, dynamic>> myImages = [];
    try {
      final String? userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        myImages = await DbService.getGalleryImagesByUser(userId);
      }
    } catch (_) {
      // ignore errors; myImages remains empty
    }
    final List<Map<String, dynamic>> likedImages = _images
        .where((img) => _likedImageIds.contains(img['id'] as int))
        .toList();
    Navigator.of(context).pushNamed(
      '/gallery/profile',
      arguments: {
        'likedImages': likedImages,
        'myImages': myImages,
      },
    );
  }

  /// Builds a simple dropdown for selecting a filter option. Passing
  /// `null` resets the filter. The dropdown displays the current
  /// selection and allows changing it.
  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String?>(
      value: value,
      hint: Text(label),
      onChanged: onChanged,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Alle'),
        ),
        ...options.map((opt) => DropdownMenuItem<String?>(
              value: opt,
              child: Text(opt),
            )),
      ],
    );
  }
}