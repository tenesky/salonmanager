import 'package:flutter/material.dart';
import '../../../common/themed_background.dart';

/// Home page for customers. This screen shows a simple search field,
/// a placeholder map section and a few recommended salons. It serves
/// as the landing page after login and does not require backend
/// interaction. Navigation to the full salon list is provided at the
/// bottom.
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Salons suchen...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Map placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Text(
                    'Kartenansicht (Placeholder)',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Empfohlene Salons',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // List of recommended salons (static sample data)
              Column(
                children: [
                  _SalonCard(
                    name: 'Salon Elegance',
                    distance: '1,2 km',
                    rating: 4.8,
                    priceLevel: '\$\$',
                  ),
                  const SizedBox(height: 12),
                  _SalonCard(
                    name: 'Hair Couture',
                    distance: '2,5 km',
                    rating: 4.6,
                    priceLevel: '\$\$\$',
                  ),
                    const SizedBox(height: 12),
                    _SalonCard(
                    name: 'Golden Scissors',
                    distance: '3,0 km',
                    rating: 4.7,
                    priceLevel: '\$\$',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/salon-list');
                  },
                  child: const Text('Alle Salons anzeigen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple card widget representing a salon. In a production app this
/// would likely be a separate file and include an image and more
/// detailed styling.
class _SalonCard extends StatelessWidget {
  final String name;
  final String distance;
  final double rating;
  final String priceLevel;

  const _SalonCard({
    required this.name,
    required this.distance,
    required this.rating,
    required this.priceLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.store, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Row(
          children: [
            Icon(Icons.star, size: 16, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text(rating.toString()),
            const SizedBox(width: 8),
            const Icon(Icons.location_on, size: 16),
            const SizedBox(width: 4),
            Text(distance),
            const SizedBox(width: 8),
            const Icon(Icons.attach_money, size: 16),
            const SizedBox(width: 2),
            Text(priceLevel),
          ],
        ),
        onTap: () {
          // In a full implementation, this would open the salon detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Salon "$name" ausgewählt (Demo)')),
          );
        },
      ),
    );
  }
}