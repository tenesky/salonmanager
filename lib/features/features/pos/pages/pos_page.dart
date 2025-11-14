import 'package:flutter/material.dart';
import '../../../services/db_service.dart';

/// Minimal POS (Point of Sale) page.  Allows searching for a customer
/// (or selecting "Gast"), adding services and products to a cart,
/// viewing the cart summary and completing a transaction via a
/// "Bezahlen" button.  This implements the basic POS flow without
/// payment method selection.  Transactions are recorded in Supabase
/// using the existing `transactions` and `transaction_items` tables.
class PosPage extends StatefulWidget {
  const PosPage({Key? key}) : super(key: key);

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  // Customer search text controller.
  final TextEditingController _customerSearchController = TextEditingController();
  // List of customers for suggestion; loaded lazily when the page opens.
  List<Map<String, dynamic>> _customers = [];
  bool _loadingCustomers = false;
  Map<String, dynamic>? _selectedCustomer; // null for guest

  // Lists of services and products loaded from Supabase.
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _products = [];
  bool _loadingItems = false;

  // Cart items. Each entry contains a map with keys: type ('product'/'service'),
  // id, name, price, quantity.
  final List<Map<String, dynamic>> _cart = [];
  bool _processingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadCustomers();
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

  /// Loads products and services from Supabase. Products and services
  /// are merged into two separate lists for selection.
  Future<void> _loadItems() async {
    setState(() {
      _loadingItems = true;
    });
    try {
      final services = await DbService.getServices();
      final products = await DbService.getProducts();
      setState(() {
        _services = services;
        _products = products;
      });
    } catch (_) {
      // ignore errors for now
    } finally {
      setState(() {
        _loadingItems = false;
      });
    }
  }

  /// Loads a list of customers for auto‑complete suggestions. Only
  /// basic fields are loaded (id and name). On Supabase errors, the
  /// list remains empty.
  Future<void> _loadCustomers() async {
    setState(() {
      _loadingCustomers = true;
    });
    try {
      final customers = await DbService.getCustomers();
      setState(() {
        _customers = customers;
      });
    } catch (_) {
      // ignore errors
    } finally {
      setState(() {
        _loadingCustomers = false;
      });
    }
  }

  /// Adds an item to the cart. If the item already exists in the cart,
  /// increases its quantity by one.
  void _addToCart({required String type, required int id, required String name, required num price}) {
    final existingIndex = _cart.indexWhere((e) => e['type'] == type && e['id'] == id);
    if (existingIndex >= 0) {
      setState(() {
        _cart[existingIndex]['quantity'] = _cart[existingIndex]['quantity'] + 1;
      });
    } else {
      setState(() {
        _cart.add({
          'type': type,
          'id': id,
          'name': name,
          'price': price,
          'quantity': 1,
        });
      });
    }
  }

  /// Calculates the total amount in the cart.
  num get _cartTotal {
    num total = 0;
    for (final item in _cart) {
      total += (item['price'] as num) * (item['quantity'] as num);
    }
    return total;
  }

  /// Handles the payment action. Creates a transaction in Supabase and
  /// clears the cart. Shows success or error feedback via snackbar.
  Future<void> _pay() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warenkorb ist leer.')), 
      );
      return;
    }
    if (_processingPayment) return;
    setState(() {
      _processingPayment = true;
    });
    try {
      final List<Map<String, dynamic>> items = _cart.map((e) {
        return {
          'type': e['type'],
          'product_id': e['type'] == 'product' ? e['id'] : null,
          'service_id': e['type'] == 'service' ? e['id'] : null,
          'name': e['name'],
          'quantity': e['quantity'],
          'unit_price': e['price'],
          'total_price': (e['price'] as num) * (e['quantity'] as num),
        };
      }).toList();
      await DbService.createTransaction(
        customerId: _selectedCustomer != null ? _selectedCustomer!['id'] as int : null,
        // For now no salon id available in the UI; pass null so it remains NULL.
        salonId: null,
        totalAmount: _cartTotal,
        paymentMethod: 'cash',
        items: items,
      );
      setState(() {
        _cart.clear();
        _selectedCustomer = null;
        _customerSearchController.clear();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bezahlung abgeschlossen')), 
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Speichern der Transaktion')), 
        );
      }
    } finally {
      setState(() {
        _processingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasse'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer selection
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (opt) => opt['name'] as String,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                return _customers.where((c) => (c['name'] as String).toLowerCase().contains(query));
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _customerSearchController.value = controller.value;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Kunde suchen',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                );
              },
              onSelected: (option) {
                setState(() {
                  _selectedCustomer = option;
                });
              },
            ),
          ),
          // Optionally show selected customer or Guest
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text('Kunde:'),
                const SizedBox(width: 8),
                if (_selectedCustomer != null)
                  Chip(
                    label: Text(_selectedCustomer!['name'] as String),
                    onDeleted: () {
                      setState(() {
                        _selectedCustomer = null;
                        _customerSearchController.clear();
                      });
                    },
                  )
                else
                  const Text('Gast'),
              ],
            ),
          ),
          const Divider(),
          // Items selection area
          Expanded(
            child: _loadingItems
                ? const Center(child: CircularProgressIndicator())
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Leistungen'),
                            Tab(text: 'Produkte'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Services list
                              ListView.builder(
                                itemCount: _services.length,
                                itemBuilder: (context, index) {
                                  final svc = _services[index];
                                  return ListTile(
                                    title: Text(svc['name'] as String),
                                    subtitle: Text('${svc['duration']} min'),
                                    trailing: Text('${svc['price']}€'),
                                    onTap: () {
                                      _addToCart(
                                        type: 'service',
                                        id: svc['id'] as int,
                                        name: svc['name'] as String,
                                        price: svc['price'] as num,
                                      );
                                    },
                                  );
                                },
                              ),
                              // Products list
                              ListView.builder(
                                itemCount: _products.length,
                                itemBuilder: (context, index) {
                                  final prod = _products[index];
                                  return ListTile(
                                    title: Text(prod['name'] as String),
                                    subtitle: Text(prod['sku'] ?? ''),
                                    trailing: Text('${prod['price']}€'),
                                    onTap: () {
                                      _addToCart(
                                        type: 'product',
                                        id: prod['id'] as int,
                                        name: prod['name'] as String,
                                        price: prod['price'] as num,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const Divider(),
          // Cart summary and pay button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Warenkorb (${_cart.length} Artikel)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 100,
                  child: _cart.isEmpty
                      ? const Center(child: Text('Noch nichts hinzugefügt.'))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return ListTile(
                              title: Text('${item['name']} x${item['quantity']}'),
                              trailing: Text('${(item['price'] as num) * (item['quantity'] as num)}€'),
                              onLongPress: () {
                                // Remove item on long press
                                setState(() {
                                  _cart.removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Summe:'),
                    Text('${_cartTotal.toStringAsFixed(2)}€'),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processingPayment ? null : _pay,
                    child: _processingPayment
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Bezahlen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}