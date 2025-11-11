import 'package:flutter/material.dart';

/// A page displaying a list of salons. This implementation uses
/// static sample data to populate the list. Later the data can be
/// fetched from a backend or local database.
class SalonListPage extends StatelessWidget {
  const SalonListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final salons = [
      {
        'name': 'Salon Elegance',
        'distance': '1,2 km',
        'rating': 4.8,
        'priceLevel': '\$\$',
      },
      {
        'name': 'Hair Couture',
        'distance': '2,5 km',
        'rating': 4.6,
        'priceLevel': '\$\$\$',
      },
      {
        'name': 'Golden Scissors',
        'distance': '3,0 km',
        'rating': 4.7,
        'priceLevel': '\$\$',
      },
      {
        'name': 'Style Studio',
        'distance': '4,1 km',
        'rating': 4.5,
        'priceLevel': '\$\$\$\$',
      },
      {
        'name': 'Beauty Bar',
        'distance': '5,0 km',
        'rating': 4.4,
        'priceLevel': '\$',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salons in deiner Nähe'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: salons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final salon = salons[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.store, color: Colors.white),
              ),
              title: Text(salon['name'] as String),
              subtitle: Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                  const SizedBox(width: 4),
                  Text((salon['rating'] as double).toString()),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(salon['distance'] as String),
                  const SizedBox(width: 8),
                  const Icon(Icons.attach_money, size: 16),
                  const SizedBox(width: 2),
                  Text(salon['priceLevel'] as String),
                ],
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Salon "${salon['name']}" ausgewählt (Demo)')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}