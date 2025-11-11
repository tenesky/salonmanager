import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salonmanager/services/db_service.dart';

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
  /// List of stylists loaded from the database.
  List<Map<String, dynamic>> _stylists = [];
  /// List of services loaded from the database.
  List<Map<String, dynamic>> _services = [];
  /// Stores the price, duration and activation state for each service per stylist.
  /// The first key is the service id, the second key is the stylist id.
  Map<int, Map<int, Map<String, dynamic>>> _cellData = {};
  /// Indicates whether data is currently being loaded.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads stylists, services and existing employee_service overrides from
  /// the database. Populates the [_stylists], [_services] and
  /// [_cellData] structures. Default price and duration values come
  /// from the services table. The active flag defaults to false
  /// unless an override exists.
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    try {
      final conn = await DbService.getConnection();
      // Load stylists
      final stylistResults = await conn.query('SELECT id, name FROM stylists ORDER BY id');
      final List<Map<String, dynamic>> stylists = [];
      for (final row in stylistResults) {
        stylists.add({'id': row['id'], 'name': row['name']});
      }
      // Load services
      final serviceResults = await conn.query('SELECT id, name, price, duration FROM services ORDER BY id');
      final List<Map<String, dynamic>> services = [];
      for (final row in serviceResults) {
        services.add({
          'id': row['id'],
          'name': row['name'],
          'price': row['price'],
          'duration': row['duration'],
        });
      }
      // Load existing overrides
      final overrideResults = await conn.query(
        'SELECT stylist_id, service_id, price, duration, active FROM employee_service',
      );
      final Map<String, Map<String, dynamic>> overrides = {};
      for (final row in overrideResults) {
        overrides['${row['service_id']}_${row['stylist_id']}'] = {
          'price': row['price'],
          'duration': row['duration'],
          'active': row['active'] == 1 || row['active'] == true,
        };
      }
      // Build cell data
      final Map<int, Map<int, Map<String, dynamic>>> cellData = {};
      for (final service in services) {
        final int sid = service['id'] as int;
        cellData[sid] = {};
        for (final stylist in stylists) {
          final int stid = stylist['id'] as int;
          final key = '${sid}_${stid}';
          if (overrides.containsKey(key)) {
            final override = overrides[key]!;
            cellData[sid]![stid] = {
              'price': override['price'] ?? service['price'],
              'duration': override['duration'] ?? service['duration'],
              'active': override['active'] ?? false,
            };
          } else {
            cellData[sid]![stid] = {
              'price': service['price'],
              'duration': service['duration'],
              'active': false,
            };
          }
        }
      }
      await conn.close();
      setState(() {
        _stylists = stylists;
        _services = services;
        _cellData = cellData;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildTable(),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  // Persist the matrix values to the database. Use an
                  // upsert to either insert a new record or update an
                  // existing one.
                  try {
                    final conn = await DbService.getConnection();
                    for (final serviceEntry in _cellData.entries) {
                      final int sid = serviceEntry.key;
                      final Map<int, Map<String, dynamic>> stylistMap = serviceEntry.value;
                      for (final stylistEntry in stylistMap.entries) {
                        final int stid = stylistEntry.key;
                        final Map<String, dynamic> cell = stylistEntry.value;
                        final double price = cell['price'] as double;
                        final int duration = cell['duration'] as int;
                        final bool active = cell['active'] as bool;
                        // Build the SQL upsert outside of the query call. If this multi‑line
                        // literal were passed directly into conn.query it could be parsed
                        // incorrectly by the Dart compiler, leading to syntax errors during
                        // the iOS build. Using a local variable ensures the string is
                        // recognised as a single argument.
                        const String upsertEmployeeService = '''
INSERT INTO employee_service (stylist_id, service_id, price, duration, active)
VALUES (?, ?, ?, ?, ?)
ON DUPLICATE KEY UPDATE price = VALUES(price), duration = VALUES(duration), active = VALUES(active)
''';
                        await conn.query(
                          upsertEmployeeService,
                          [stid, sid, price, duration, active ? 1 : 0],
                        );
                      }
                    }
                    await conn.close();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Leistungs-Setup gespeichert')),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fehler beim Speichern des Leistungs-Setups.')),
                    );
                  }
                },
          child: const Text('Speichern'),
        ),
      ),
    );
  }
}