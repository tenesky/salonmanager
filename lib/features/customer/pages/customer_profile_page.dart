import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/customer_history_tab.dart';
import '../widgets/customer_notes_tab.dart';
import 'package:salonmanager/services/db_service.dart';

/// Page displaying a customer's profile with tabs for history, notes and images.
/// The top section shows basic data such as photo, name and contact details.
/// Below it, a [TabBar] allows switching between the three sections without
/// reloading the entire page. This page corresponds to Screen 45 in the
/// requirements specification.
class CustomerProfilePage extends StatefulWidget {
  /// The id of the customer to display. Must be provided via route arguments.
  final int customerId;
  const CustomerProfilePage({Key? key, required this.customerId})
      : super(key: key);

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage>
    with SingleTickerProviderStateMixin {
  /// Controller for switching between tabs.
  late final TabController _tabController;
  /// Holds customer data loaded from the database.
  Map<String, dynamic>? _customer;
  /// Loading indicator for fetching customer data.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads the customer from the database based on [widget.customerId].
  Future<void> _loadCustomer() async {
    setState(() {
      _loading = true;
    });
    try {
      final Map<String, dynamic>? row = await DbService.getCustomerById(widget.customerId);
      if (row != null) {
        // Parse last_visit_date to DateTime if provided as string
        final dynamic dateVal = row['last_visit_date'];
        DateTime? lastVisit;
        if (dateVal is String && dateVal.isNotEmpty) {
          lastVisit = DateTime.tryParse(dateVal);
        } else if (dateVal is DateTime) {
          lastVisit = dateVal;
        }
        setState(() {
          _customer = {
            'id': row['id'],
            'name': row['name'],
            'email': row['email'],
            'phone': row['phone'],
            'photo_url': row['photo_url'],
            'last_visit_date': lastVisit,
            'is_regular': row['is_regular'] == true || row['is_regular'] == 1,
            'no_show_count': row['no_show_count'] ?? 0,
          };
        });
      }
    } catch (_) {
      // Ignore errors; _customer remains null.
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kundenprofil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _customer == null
              ? const Center(child: Text('Kunde nicht gefunden.'))
              : Column(
                  children: [
                    // Top section with basic information
                    _buildHeader(context),
                    // Tab bar for switching sections
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Historie'),
                        Tab(text: 'Notizen'),
                        Tab(text: 'Bilder'),
                      ],
                    ),
                    // Tab views for content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHistoryTab(),
                          _buildNotesTab(),
                          _buildImagesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Builds the header containing the customer's photo, name and contact details.
  Widget _buildHeader(BuildContext context) {
    final photoUrl = _customer!['photo_url'] as String?;
    final name = _customer!['name'] as String;
    final email = _customer!['email'] as String?;
    final phone = _customer!['phone'] as String?;
    final lastVisit = _customer!['last_visit_date'] as DateTime?;
    final isRegular = _customer!['is_regular'] == true;
    final noShowCount = _customer!['no_show_count'] as int;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 8),
                if (email != null && email.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 4),
                      Text(email),
                    ],
                  ),
                if (phone != null && phone.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 4),
                      Text(phone),
                    ],
                  ),
                if (lastVisit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Letzter Besuch: ${DateFormat('dd.MM.yyyy').format(lastVisit)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the history tab widget. Displays a list of past bookings and
  /// purchases with filtering and export options. Delegates to
  /// [CustomerHistoryTab].
  Widget _buildHistoryTab() {
    return CustomerHistoryTab(customerId: widget.customerId, isManager: true);
  }

  /// Placeholder widget for the notes tab. Will be implemented in
  /// subsequent iterations (Screen 47).
  Widget _buildNotesTab() {
    return CustomerNotesTab(customerId: widget.customerId);
  }

  /// Placeholder widget for the images tab. Users can view before/after
  /// photos of treatments. Implementation will follow later.
  Widget _buildImagesTab() {
    return const Center(
      child: Text('Bilder werden hier angezeigt.'),
    );
  }
}