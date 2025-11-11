import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A page that allows managers or stylists to configure which services
/// each stylist offers and to override the default price and duration
/// per service. The UI presents a matrix (services × stylists) where
/// each cell contains input fields for price and duration and a toggle
/// to activate or deactivate the service for that stylist. This
/// implements Screen 35 in the Realisierungsplan, which specifies a
/// matrix with editable cells for price and duration【73678961014422†L1515-L1519】.
class ServiceSetupPage extends StatefulWidget {
  const ServiceSetupPage({Key? key}) : super(key: key);

  @override
  State<ServiceSetupPage> createState() => _ServiceSetupPageState();
}

class _ServiceSetupPageState extends State<ServiceSetupPage> {
  // Example stylists. In a real application these would be loaded from
  // the backend. Each has a unique id and a display name.
  final List<Map<String, dynamic>> _stylists = [
    {'id': 1, 'name': 'Max'},
    {'id': 2, 'name': 'Sofia'},
    {'id': 3, 'name': 'Tom'},
  ];

  // Example services. These represent the available treatments or
  // appointments. Each has a unique id and a descriptive name.
  final List<Map<String, dynamic>> _services = [
    {'id': 1, 'name': 'Haarschnitt'},
    {'id': 2, 'name': 'Färben'},
    {'id': 3, 'name': 'Balayage'},
    {'id': 4, 'name': 'Styling'},
  ];

  /// Stores the price, duration and activation state for each service
  /// per stylist. The first key is the service id, the second key is
  /// the stylist id. Each value is a map containing:
  ///  - price: double (in EUR)
  ///  - duration: int (minutes)
  ///  - active: bool
  late final Map<int, Map<int, Map<String, dynamic>>> _cellData;

  @override
  void initState() {
    super.initState();
    _initCellData();
  }

  void _initCellData() {
    _cellData = {};
    for (final service in _services) {
      final int sid = service['id'] as int;
      _cellData[sid] = {};
      for (final stylist in _stylists) {
        final int stid = stylist['id'] as int;
        _cellData[sid]![stid] = {
          'price': 50.0,
          'duration': 60,
          'active': true,
        };
      }
    }
  }

  /// Builds the table header row with a blank cell for the service
  /// column followed by one header per stylist.
  TableRow _buildHeaderRow() {
    return TableRow(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Leistung',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        for (final stylist in _stylists)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              stylist['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Builds a single cell with input fields for price and duration and a
  /// toggle switch for activation. [serviceId] and [stylistId] identify
  /// the cell in the [_cellData] map.
  Widget _buildCell(int serviceId, int stylistId) {
    final cell = _cellData[serviceId]![stylistId]!;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: (cell['price'] as double).toStringAsFixed(2),
            decoration: const InputDecoration(
              labelText: 'Preis (€)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+([,.][0-9]{0,2})?')),
            ],
            onChanged: (value) {
              setState(() {
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed != null) {
                  cell['price'] = parsed;
                }
              });
            },
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: (cell['duration'] as int).toString(),
            decoration: const InputDecoration(
              labelText: 'Dauer (min)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {
                final parsed = int.tryParse(value);
                if (parsed != null) {
                  cell['duration'] = parsed;
                }
              });
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Aktiv'),
              Switch(
                value: cell['active'] as bool,
                onChanged: (value) {
                  setState(() {
                    cell['active'] = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the entire table as a [Table] widget. The header row is
  /// added first, then one row per service. Each cell is created via
  /// [_buildCell]. Column widths are fixed to ensure a consistent layout
  /// and horizontal scrolling is enabled at the page level.
  Widget _buildTable() {
    final rows = <TableRow>[_buildHeaderRow()];
    for (final service in _services) {
      final int sid = service['id'] as int;
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(service['name'] as String),
            ),
            for (final stylist in _stylists)
              _buildCell(sid, stylist['id'] as int),
          ],
        ),
      );
    }
    return Table(
      border: TableBorder.all(color: Theme.of(context).dividerColor),
      columnWidths: {
        0: const FixedColumnWidth(120),
        for (int i = 1; i <= _stylists.length; i++) i: const FixedColumnWidth(200),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leistungs-Setup je Stylist'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildTable(),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // In a real implementation, here you would persist the data to the
            // backend. For now we just show a confirmation snackbar.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Leistungs-Setup gespeichert')),
            );
          },
          child: const Text('Speichern'),
        ),
      ),
    );
  }
}