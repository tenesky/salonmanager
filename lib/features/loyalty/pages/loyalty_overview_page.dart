import 'package:flutter/material.dart';
import '../../../services/db_service.dart';

/// Displays a simple loyalty overview for a customer.
///
/// This page shows the customer's current loyalty points, their
/// membership level and a list of possible rewards. A progress bar
/// indicates how far the customer is from reaching the next level.
/// For now the values are static placeholders to demonstrate the
/// layout and behaviour. In a future version these values will be
/// fetched from Supabase based on the salon's loyalty program and
/// the customer's account.
class LoyaltyOverviewPage extends StatefulWidget {
  const LoyaltyOverviewPage({Key? key}) : super(key: key);

  @override
  State<LoyaltyOverviewPage> createState() => _LoyaltyOverviewPageState();
}

class _LoyaltyOverviewPageState extends State<LoyaltyOverviewPage> {
  bool _loading = true;
  int _points = 0;
  String _level = '';
  String? _nextLevelName;
  int _pointsToNext = 0;
  List<Map<String, dynamic>> _availableRewards = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
    });
    try {
      final status = await DbService.getLoyaltyStatus();
      setState(() {
        _points = status['points'] as int? ?? 0;
        _level = (status['level'] as String?) ?? '';
        _nextLevelName = status['nextLevelName'] as String?;
        _pointsToNext = status['pointsToNext'] as int? ?? 0;
        _availableRewards = List<Map<String, dynamic>>.from(
            status['availableRewards'] as List<dynamic>? ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _redeem(Map<String, dynamic> reward) async {
    try {
      await DbService.redeemReward(reward);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reward eingelöst'),
            content: Text(
                'Du hast "${reward['name']}" eingelöst. Vielen Dank für deine Treue!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      // Reload status to update points and rewards
      await _loadStatus();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler beim Einlösen: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treue‑Programm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatus,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dein aktueller Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Punkte',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      '$_points',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Level',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      _level.isNotEmpty ? _level : '–',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: (_pointsToNext == 0 && _nextLevelName == null)
                                  ? 1.0
                                  : (_points / ((_points + _pointsToNext).toDouble())),
                              minHeight: 8,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _nextLevelName != null
                                  ? '$_points / ${_points + _pointsToNext} Punkte bis $_nextLevelName'
                                  : 'Maximales Level erreicht',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Mögliche Rewards',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_availableRewards.isEmpty)
                      const Text('Keine Rewards verfügbar'),
                    for (final reward in _availableRewards) ...[
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(reward['name']?.toString() ?? ''),
                          subtitle: Text(reward['description']?.toString() ?? ''),
                          trailing: ElevatedButton(
                            onPressed: () => _redeem(reward),
                            child: const Text('Einlösen'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}