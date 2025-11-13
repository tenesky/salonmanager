import 'package:flutter/material.dart';

/// Displays a simple loyalty overview for a customer.
///
/// This page shows the customer's current loyalty points, their
/// membership level and a list of possible rewards. A progress bar
/// indicates how far the customer is from reaching the next level.
/// For now the values are static placeholders to demonstrate the
/// layout and behaviour. In a future version these values will be
/// fetched from Supabase based on the salon's loyalty program and
/// the customer's account.
class LoyaltyOverviewPage extends StatelessWidget {
  const LoyaltyOverviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Static demo values. In production these would come from the backend.
    const int currentPoints = 350;
    const int nextLevelPoints = 500;
    const String currentLevel = 'Bronze';
    const String nextLevel = 'Silber';
    // Example rewards for demonstration purposes. Salons can configure
    // their own rewards or disable the loyalty program entirely.
    const List<Map<String, String>> rewards = [
      {
        'title': '5 € Gutschein',
        'description': 'Einlösbar bei deinem nächsten Besuch',
      },
      {
        'title': 'Gratis Pflegeprodukt',
        'description': 'Wähle aus unserem Sortiment',
      },
      {
        'title': '10 % Rabatt',
        'description': 'Auf einen ausgewählten Service',
      },
    ];

    final double progress = currentPoints / nextLevelPoints;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treue‑Programm'),
      ),
      body: Padding(
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
                                '$currentPoints',
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
                                currentLevel,
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
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$currentPoints / $nextLevelPoints Punkte bis $nextLevel',
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
              for (final reward in rewards) ...[
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(reward['title'] ?? ''),
                    subtitle: Text(reward['description'] ?? ''),
                    trailing: const Icon(Icons.card_giftcard),
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