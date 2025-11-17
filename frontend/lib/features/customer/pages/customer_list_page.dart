import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonmanager/services/db_service.dart';

/// Page displaying a searchable and filterable list of customers. A
/// search bar, filter toggles for regular and no‑show customers and
/// sort selection are provided. Each customer card shows the name,
/// date of last visit, a no‑show marker and a "Stammkunde" badge if
/// applicable. Tapping a customer opens their profile page. This
/// implements Screen 44 from the requirements.
class CustomerListPage extends StatefulWidget {
  const CustomerListPage({Key? key}) : super(key: key);

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  /// All customers loaded from the database.
  List<Map<String, dynamic>> _customers = [];
  /// Customers after applying filters and sorting.
  List<Map<String, dynamic>> _filtered = [];
  /// Loading indicator flag.
  bool _loading = false;
  /// Filter: show only regular customers.
  bool _filterRegular = false;
  /// Filter: show only customers with no‑show flags (no_show_count > 0).
  bool _filterNoShow = false;
  /// Current sort option ('name' or 'last_visit').
  String _sortBy = 'name';
  /// Search query controller.
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads customer data from the database. Each customer should have
  /// id, name, last_visit_date (nullable), no_show_count and is_regular.
  Future<void> _loadCustomers() async {
    setState(() {
      _loading = true;
    });
    try {
      // Fetch customers from Supabase.  Sorting by name by default.
      final result = await DbService.getCustomers(sortBy: 'name');
      final List<Map<String, dynamic>> customers = [];
      for (final row in result) {
        // Supabase returns last_visit_date as a string; parse to DateTime if available.
        final dynamic dateVal = row['last_visit_date'];
        DateTime? lastVisit;
        if (dateVal is String && dateVal.isNotEmpty) {
          lastVisit = DateTime.tryParse(dateVal);
        } else if (dateVal is DateTime) {
          lastVisit = dateVal;
        }
        customers.add({
          'id': row['id'],
          'name': row['name'],
          'last_visit_date': lastVisit,
          'no_show_count': row['no_show_count'] ?? 0,
          'is_regular': row['is_regular'] == true || row['is_regular'] == 1,
        });
      }
      setState(() {
        _customers = customers;
        _loading = false;
      });
      _applyFilters();
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Applies the current search, filter and sort settings to the
  /// customer list and updates [_filtered].
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(_customers);
    // Search by name
    if (query.isNotEmpty) {
      list = list
          .where((c) => (c['name'] as String).toLowerCase().contains(query))
          .toList();
    }
    // Filter by regular customers
    if (_filterRegular) {
      list = list.where((c) => c['is_regular'] == true).toList();
    }
    // Filter by no‑show
    if (_filterNoShow) {
      list = list.where((c) => (c['no_show_count'] ?? 0) > 0).toList();
    }
    // Sort
    if (_sortBy == 'name') {
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } else if (_sortBy == 'last_visit') {
      list.sort((a, b) {
        final aDate = a['last_visit_date'] as DateTime?;
        final bDate = b['last_visit_date'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    }
    setState(() {
      _filtered = list;
    });
  }

  /// Navigates to the customer profile page when a customer card is tapped.
  void _openCustomerProfile(Map<String, dynamic> customer) {
    final id = customer['id'];
    // Navigate to the customer profile route and pass the id via arguments.
    Navigator.of(context).pushNamed('/crm/customer', arguments: {'id': id});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kundenliste'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Suche nach Name',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            // Filter row
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Stammkunde'),
                    value: _filterRegular,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterRegular = value;
                        });
                        _applyFilters();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('No‑Show'),
                    value: _filterNoShow,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterNoShow = value;
                        });
                        _applyFilters();
                      }
                    },
                  ),
                ),
                // Sort dropdown
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('A–Z')),
                    DropdownMenuItem(value: 'last_visit', child: Text('Letzter Besuch')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                      _applyFilters();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Customer list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(child: Text('Keine Kunden gefunden.'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final customer = _filtered[index];
                            final name = customer['name'] as String;
                            final lastVisit = customer['last_visit_date'] as DateTime?;
                            final noShowCount = customer['no_show_count'] ?? 0;
                            final isRegular = customer['is_regular'] == true;
                            return Card(
                              child: ListTile(
                                onTap: () => _openCustomerProfile(customer),
                                title: Text(name),
                                subtitle: Text(lastVisit != null
                                    ? 'Letzter Besuch: ${DateFormat('dd.MM.yyyy').format(lastVisit)}'
                                    : 'Noch kein Besuch'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isRegular)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Stamm',
                                          style: TextStyle(fontSize: 10, color: Colors.green),
                                        ),
                                      ),
                                    if (noShowCount > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'No‑Show',
                                            style: TextStyle(fontSize: 10, color: Colors.red.shade700),
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
          ],
        ),
      ),
    );
  }
}