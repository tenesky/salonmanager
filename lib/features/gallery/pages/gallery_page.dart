import 'package:flutter/material.dart';

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
  // Define some demo images with metadata. In a future iteration
  // these will be loaded from the Supabase `gallery_images` table.
  final List<Map<String, dynamic>> _images = [
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

  /// Returns the list of images matching the current filter settings.
  List<Map<String, dynamic>> get _filteredImages {
    return _images.where((img) {
      final bool lengthOk = _selectedLength == null || img['length'] == _selectedLength;
      final bool styleOk = _selectedStyle == null || img['style'] == _selectedStyle;
      final bool colourOk = _selectedColour == null || img['colour'] == _selectedColour;
      return lengthOk && styleOk && colourOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galerie'),
      ),
      body: Column(
        children: [
          // Filter chips row. Use Wrap to allow chips to wrap on small screens.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  _buildDropdownFilter(
                    label: 'Länge',
                    value: _selectedLength,
                    options: _lengthOptions,
                    onChanged: (val) {
                      setState(() {
                        _selectedLength = val;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownFilter(
                    label: 'Stil',
                    value: _selectedStyle,
                    options: _styleOptions,
                    onChanged: (val) {
                      setState(() {
                        _selectedStyle = val;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownFilter(
                    label: 'Farbe',
                    value: _selectedColour,
                    options: _colourOptions,
                    onChanged: (val) {
                      setState(() {
                        _selectedColour = val;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // Reset filters button
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedLength = null;
                        _selectedStyle = null;
                        _selectedColour = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: _filteredImages.length,
                itemBuilder: (context, index) {
                  final img = _filteredImages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/gallery/detail',
                        arguments: img,
                      );
                    },
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              img['asset'] as String,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Overlay gradient and text
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                img['description'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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