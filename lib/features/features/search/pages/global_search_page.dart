import 'package:flutter/material.dart';

/// A simple global search page with tabs for salons, services and stylists.
///
/// This page demonstrates a client‑side search over three static lists.
/// The user enters a query in the search field and results are updated
/// in realtime. Each tab shows the filtered entries for that category.
/// In a future implementation this could query Supabase using SQL LIKE
/// across multiple tables. For now the lists are hard‑coded for
/// demonstration purposes.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({Key? key}) : super(key: key);

  @override
  _GlobalSearchPageState createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  // Static demo data. In a real app these would be loaded from the
  // database or via API.  Each list contains strings representing the
  // entity names.
  final List<String> _allSalons = [
    'Salon Elegance',
    'Golden Scissors',
    'City Cuts',
    'Hair Couture',
    'Stylish Trends',
  ];
  final List<String> _allServices = [
    'Haarschnitt',
    'Färben',
    'Bart trimmen',
    'Maniküre',
    'Pediküre',
  ];
  final List<String> _allStylists = [
    'Anna',
    'Paul',
    'Lisa',
    'Michael',
    'Sara',
  ];
  // Filtered lists that update based on the search query.
  List<String> _filteredSalons = [];
  List<String> _filteredServices = [];
  List<String> _filteredStylists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filteredSalons = List.from(_allSalons);
    _filteredServices = List.from(_allServices);
    _filteredStylists = List.from(_allStylists);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Applies the search filter to all three lists.  The filtering is
  /// case‑insensitive and matches substrings in the name.  When the
  /// search query is empty all items are shown.
  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredSalons = List.from(_allSalons);
        _filteredServices = List.from(_allServices);
        _filteredStylists = List.from(_allStylists);
      } else {
        _filteredSalons =
            _allSalons.where((s) => s.toLowerCase().contains(query)).toList();
        _filteredServices =
            _allServices.where((s) => s.toLowerCase().contains(query)).toList();
        _filteredStylists =
            _allStylists.where((s) => s.toLowerCase().contains(query)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Suche'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Salons'),
              Tab(text: 'Services'),
              Tab(text: 'Stylisten'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Suchbegriff',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildListView(_filteredSalons, 'Keine Salons gefunden.'),
                  _buildListView(_filteredServices, 'Keine Services gefunden.'),
                  _buildListView(_filteredStylists, 'Keine Stylisten gefunden.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a simple list view for a given set of results. If the list
  /// is empty a placeholder text is shown instead.
  Widget _buildListView(List<String> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index]),
        );
      },
    );
  }
}