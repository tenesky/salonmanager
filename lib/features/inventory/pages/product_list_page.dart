import 'package:flutter/material.dart';
import '../../../services/db_service.dart';

/// Page showing a simple inventory list with search and category filter.
///
/// Products are loaded from the Supabase `products` table. The list
/// displays columns for name, SKU, category, price and quantity. A
/// search field allows filtering by product name and a dropdown lets
/// users filter by category. The data is refreshed whenever the
/// search query or selected category changes. Errors while loading
/// products are silently ignored; an empty list will be shown in
/// that case.
class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads products from the database based on the current search
  /// query and selected category. After fetching the list, the
  /// distinct categories are derived from the results to populate
  /// the category filter. Errors are silently ignored.
  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
    });
    try {
      final products = await DbService.getProducts(
        searchQuery: _searchController.text,
        categoryFilter: (_selectedCategory == null || _selectedCategory == 'Alle')
            ? null
            : _selectedCategory,
      );
      final cats = <String>{};
      for (final p in products) {
        final dynamic c = p['category'];
        if (c != null && c.toString().isNotEmpty) {
          cats.add(c.toString());
        }
      }
      setState(() {
        _products = products;
        _categories = ['Alle'] + cats.toList()..sort();
      });
    } catch (_) {
      // ignore errors; _products remains empty
      setState(() {
        _products = [];
        _categories = ['Alle'];
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Builds the search and category filter row. When the user types
  /// in the search field or selects a category, the product list is
  /// reloaded with the new criteria.
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Suche Produkt',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _loadProducts(),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedCategory ?? 'Alle',
            items: _categories
                .map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c.isEmpty ? '(Kategorie unbekannt)' : c),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              _loadProducts();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produktliste'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Keine Produkte gefunden.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('SKU')),
                            DataColumn(label: Text('Kategorie')),
                            DataColumn(label: Text('Preis')),
                            DataColumn(label: Text('Bestand')),
                          ],
                          rows: _products.map((p) {
                            final name = p['name']?.toString() ?? '';
                            final sku = p['sku']?.toString() ?? '';
                            final category = p['category']?.toString() ?? '';
                            final price = p['price'];
                            final quantity = p['quantity'];
                            final priceStr = price is num
                                ? '${price.toStringAsFixed(2)} €'
                                : price?.toString() ?? '';
                            final qtyStr = quantity?.toString() ?? '';
                            return DataRow(cells: [
                              DataCell(Text(name)),
                              DataCell(Text(sku)),
                              DataCell(Text(category)),
                              DataCell(Text(priceStr)),
                              DataCell(Text(qtyStr)),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}