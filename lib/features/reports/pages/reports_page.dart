import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../services/db_service.dart';

/// A dashboard page showing key performance indicators and charts for
/// managers and salon owners.  The page aggregates revenue, stylist
/// utilisation, top services, no‑show rates, loyalty statistics and
/// inventory KPIs for a selected time period (Heute, Woche, Monat,
/// Jahr).  Data is retrieved via [DbService] and visualised using
/// `fl_chart`.  Users can also export the revenue data as CSV to
/// Supabase storage.
class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // Available period filters.  Each entry maps to a function that
  // computes the start date relative to now.
  final Map<String, DateTime Function()> _periodStartFns = {
    'Heute': () {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    },
    'Diese Woche': () {
      final now = DateTime.now();
      final weekday = now.weekday;
      return now.subtract(Duration(days: weekday - 1));
    },
    'Dieser Monat': () {
      final now = DateTime.now();
      return DateTime(now.year, now.month, 1);
    },
    'Dieses Jahr': () {
      final now = DateTime.now();
      return DateTime(now.year, 1, 1);
    },
  };
  String _selectedPeriod = 'Diese Woche';
  bool _loading = true;
  Map<String, dynamic>? _revenue;
  List<Map<String, dynamic>>? _utilization;
  List<Map<String, dynamic>>? _topServices;
  Map<String, dynamic>? _noShow;
  Map<String, dynamic>? _loyalty;
  Map<String, dynamic>? _inventory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    final now = DateTime.now();
    final startFn = _periodStartFns[_selectedPeriod] ?? _periodStartFns['Diese Woche']!;
    final start = startFn();
    final end = now;
    try {
      final revenue = await DbService.getRevenueByPeriod(start: start, end: end);
      final util = await DbService.getUtilizationByStylist(start: start, end: end);
      final top = await DbService.getTopServices(start: start, end: end, limit: 5);
      final noShow = await DbService.getNoShowRates(start: start, end: end);
      final loyalty = await DbService.getLoyaltyStats();
      final inventory = await DbService.getInventoryKPI();
      setState(() {
        _revenue = revenue;
        _utilization = util;
        _topServices = top;
        _noShow = noShow;
        _loyalty = loyalty;
        _inventory = inventory;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Laden der Daten: $e')));
    }
  }

  /// Builds a line chart for revenue using [fl_chart].  Each point
  /// represents a day's total revenue.  If no data is available,
  /// returns a placeholder message.
  Widget _buildRevenueChart() {
    if (_revenue == null || (_revenue!['daily'] as List).isEmpty) {
      return const Text('Keine Umsatzdaten verfügbar');
    }
    final daily = _revenue!['daily'] as List;
    final spots = <FlSpot>[];
    final dateFormat = DateFormat('MM/dd');
    for (int i = 0; i < daily.length; i++) {
      final item = daily[i] as Map<String, dynamic>;
      final date = item['date'] as DateTime;
      final total = item['total'] as num;
      spots.add(FlSpot(i.toDouble(), total.toDouble()));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Umsatz: ${_revenue!['totalRevenue'].toStringAsFixed(2)} €',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < daily.length) {
                        final date = (daily[index]['date'] as DateTime);
                        return Text(dateFormat.format(date), style: const TextStyle(fontSize: 10));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a bar chart to display utilisation per stylist.  Each bar
  /// shows the utilisation percentage (0–100 %) for a stylist.  If
  /// there is no utilisation data, displays a placeholder message.
  Widget _buildUtilizationChart() {
    if (_utilization == null || _utilization!.isEmpty) {
      return const Text('Keine Auslastungsdaten verfügbar');
    }
    final maxUtil = _utilization!
        .map((e) => (e['utilization'] as double?) ?? 0.0)
        .fold<double>(0.0, (prev, e) => e > prev ? e : prev);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Auslastung je Stylist', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < _utilization!.length) {
                        final id = _utilization![index]['stylist_id'];
                        return Text('S$id', style: const TextStyle(fontSize: 10));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, interval: 0.2),
                ),
              ),
              borderData: FlBorderData(show: true),
              barGroups: [
                for (int i = 0; i < _utilization!.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: (_utilization![i]['utilization'] as double?) ?? 0.0,
                      width: 14,
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
              ],
              maxY: maxUtil < 1.0 ? 1.0 : maxUtil,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a pie chart for the top services.  Each slice represents
  /// the proportion of bookings for a service.  If no data is
  /// available, a placeholder is shown.
  Widget _buildTopServicesChart() {
    if (_topServices == null || _topServices!.isEmpty) {
      return const Text('Keine Top-Leistungen vorhanden');
    }
    final total = _topServices!
        .map((e) => (e['count'] as int?) ?? 0)
        .fold<int>(0, (a, b) => a + b);
    final sections = <PieChartSectionData>[];
    for (int i = 0; i < _topServices!.length; i++) {
      final item = _topServices![i];
      final count = (item['count'] as int?) ?? 0;
      final pct = total > 0 ? count / total : 0;
      sections.add(PieChartSectionData(
        value: pct,
        title: '${(pct * 100).toStringAsFixed(0)}%',
        color: Colors.primaries[i % Colors.primaries.length],
        radius: 50,
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top-Leistungen', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < _topServices!.length; i++)
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                color: Colors.primaries[i % Colors.primaries.length],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                    '${_topServices![i]['name']} (${_topServices![i]['count']})'),
              ),
            ],
          ),
      ],
    );
  }

  /// Creates a simple widget summarising no‑show rates.
  Widget _buildNoShowSummary() {
    if (_noShow == null || _noShow!['total'] == 0) {
      return const Text('Keine No-Show-Daten');
    }
    final total = _noShow!['total'] as int;
    final noShows = _noShow!['noShows'] as int;
    final rate = (_noShow!['rate'] as double?) ?? 0.0;
    final percent = (rate * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No-Shows', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Gesamt: $total'),
        Text('No-Shows: $noShows'),
        Text('Quote: $percent %'),
      ],
    );
  }

  /// Creates a widget summarising loyalty statistics.
  Widget _buildLoyaltySummary() {
    if (_loyalty == null) {
      return const Text('Keine Loyalitätsdaten');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Loyalität', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Kunden insgesamt: ${_loyalty!['totalCustomers']}'),
        Text('Ø Punkte: ${(_loyalty!['averagePoints'] as num).toStringAsFixed(1)}'),
        Text('Einlösungen: ${_loyalty!['totalRedemptions']}'),
        Text('Einlösequote: ${(100 * (_loyalty!['redemptionRate'] as double)).toStringAsFixed(1)} %'),
      ],
    );
  }

  /// Creates a widget summarising inventory KPIs.
  Widget _buildInventorySummary() {
    if (_inventory == null) {
      return const Text('Keine Inventardaten');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inventar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Produkte: ${_inventory!['totalProducts']}'),
        Text('Niedriger Bestand: ${_inventory!['lowStockCount']}'),
        Text('Gesamtwert: ${(_inventory!['totalValue'] as num).toStringAsFixed(2)} €'),
      ],
    );
  }

  /// Exports the revenue data as CSV to Supabase storage.  Creates a
  /// header row followed by date and revenue columns.  Displays a
  /// snackbar with the public URL on success.
  Future<void> _exportRevenueCsv() async {
    if (_revenue == null || (_revenue!['daily'] as List).isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Keine Umsatzdaten zum Exportieren')));
      return;
    }
    final daily = _revenue!['daily'] as List;
    final buffer = StringBuffer();
    buffer.writeln('Datum;Umsatz');
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (final item in daily) {
      final date = item['date'] as DateTime;
      final total = item['total'] as num;
      buffer.writeln('${dateFormat.format(date)};${total.toStringAsFixed(2)}');
    }
    try {
      final url = await DbService.uploadReportCSV(buffer.toString(), 'revenue.csv');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportiert: $url')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Export: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berichte & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Aktualisieren',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportRevenueCsv,
            tooltip: 'Umsatz als CSV exportieren',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period filter dropdown
            Row(
              children: [
                const Text('Zeitraum:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: _periodStartFns.keys
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedPeriod) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                      _loadData();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRevenueChart(),
                          const SizedBox(height: 24),
                          _buildUtilizationChart(),
                          const SizedBox(height: 24),
                          _buildTopServicesChart(),
                          const SizedBox(height: 24),
                          _buildNoShowSummary(),
                          const SizedBox(height: 24),
                          _buildLoyaltySummary(),
                          const SizedBox(height: 24),
                          _buildInventorySummary(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}