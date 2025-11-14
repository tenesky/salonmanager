import 'package:flutter/material.dart';
import 'package:salonmanager/services/db_service.dart';

/// A page that allows managers to assign services to stylists. The UI
/// presents a matrix (services × stylists) where each cell contains a
/// checkbox indicating whether the stylist may perform the service.
/// Toggling a checkbox immediately persists the change to the
/// database. This implements Screen 43 in the Realisierungsplan.
class AssignServicesPage extends StatefulWidget {
  const AssignServicesPage({Key? key}) : super(key: key);

  @override
  State<AssignServicesPage> createState() => _AssignServicesPageState();
}

class _AssignServicesPageState extends State<AssignServicesPage> {
  /// List of stylists loaded from the database.
  List<Map<String, dynamic>> _stylists = [];
  /// List of services loaded from the database.
  List<Map<String, dynamic>> _services = [];
  /// Indicates whether data is currently being loaded.
  bool _loading = false;
  /// Assignment state: serviceId -> stylistId -> assigned (active).
  Map<int, Map<int, bool>> _assigned = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads stylists, services and existing assignments from the database.
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    try {
      final List<Map<String, dynamic>> stylists = await DbService.getStylists();
      final List<Map<String, dynamic>> services = await DbService.getServices();
      final List<Map<String, dynamic>> assignments = await DbService.getEmployeeServices();
      final Map<int, Map<int, bool>> assigned = {};
      for (final service in services) {
        assigned[service['id'] as int] = {};
        for (final stylist in stylists) {
          assigned[service['id'] as int]![stylist['id'] as int] = false;
        }
      }
      for (final row in assignments) {
        final sid = row['service_id'] as int;
        final stid = row['stylist_id'] as int;
        final active = row['active'] == true || row['active'] == 1;
        if (assigned.containsKey(sid)) {
          assigned[sid]![stid] = active;
        }
      }
      setState(() {
        _stylists = stylists;
        _services = services;
        _assigned = assigned;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Toggles the assignment of [serviceId] to [stylistId] and persists
  /// the change to the database. If an assignment record exists, it
  /// updates the active flag; otherwise it inserts a new record with
  /// the service's default price and duration.
  Future<void> _toggleAssignment(int serviceId, int stylistId, bool value) async {
    setState(() {
      _assigned[serviceId]![stylistId] = value;
    });
    try {
      // Use upsert to create or update the assignment.  Price and
      // duration are stored in the service table, so we only need to
      // update the active flag.  Additional overrides can be passed
      // here if desired.
      await DbService.upsertEmployeeService(
        stylistId: stylistId,
        serviceId: serviceId,
        active: value,
      );
    } catch (_) {
      // If the update fails, revert the local change for consistency
      setState(() {
        _assigned[serviceId]![stylistId] = !value;
      });
    }
  }

  /// Builds the header row with service column header and stylist names.
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

  /// Builds a single table row for a given service. Contains the service
  /// name and a checkbox per stylist.
  TableRow _buildServiceRow(Map<String, dynamic> service) {
    final int serviceId = service['id'] as int;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(service['name'] as String),
        ),
        for (final stylist in _stylists)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Checkbox(
                value: _assigned[serviceId]?[stylist['id'] as int] ?? false,
                onChanged: (value) {
                  if (value != null) {
                    _toggleAssignment(serviceId, stylist['id'] as int, value);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leistungszuweisung'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stylists.isEmpty || _services.isEmpty
              ? const Center(child: Text('Keine Daten verfügbar.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        _buildHeaderRow(),
                        for (final service in _services) _buildServiceRow(service),
                      ],
                    ),
                  ),
                ),
    );
  }
}