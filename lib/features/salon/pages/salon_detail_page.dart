import 'package:flutter/material.dart';
import '../models/salon.dart';

/// Detail view for a salon. This page displays a hero area with cover
/// image and logo, salon contact details, a list of services with
/// price and duration, and a team section with photos. A
/// "Jetzt buchen"‑Button at the bottom navigates to the booking
/// wizard.
class SalonDetailPage extends StatelessWidget {
  final Salon salon;

  const SalonDetailPage({Key? key, required this.salon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Static list of services for demonstration. In a real
    // implementation these would come from the backend for this salon.
    final services = [
      {'title': 'Haarschnitt', 'price': '45 €', 'duration': '60 min'},
      {'title': 'Färben', 'price': '70 €', 'duration': '90 min'},
      {'title': 'Bart trimmen', 'price': '20 €', 'duration': '30 min'},
    ];

    // Static team members for demonstration. Each entry contains a
    // name and an asset path for the photo. These can be replaced by
    // real images and data.
    final team = [
      {'name': 'Anna', 'image': 'assets/icon_cropped.png'},
      {'name': 'Paul', 'image': 'assets/icon_cropped2.png'},
      {'name': 'Lisa', 'image': 'assets/icon_manual_crop.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(salon.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero area: cover image with logo overlay
            Stack(
              children: [
                Image.asset(
                  salon.coverImage,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(salon.logoImage),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salon.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(salon.address)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Öffnungszeiten: ${salon.openingHours}')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(salon.phone)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Services list
                  Text(
                    'Leistungen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: services
                        .map(
                          (service) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service['title'] as String),
                            subtitle: Text(service['duration'] as String),
                            trailing: Text(service['price'] as String),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  // Team section
                  Text(
                    'Unser Team',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: team
                        .map(
                          (member) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                backgroundImage:
                                    AssetImage(member['image'] as String),
                              ),
                              const SizedBox(height: 4),
                              Text(member['name'] as String),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Start the booking wizard. This navigates to the
                        // first step of the booking flow (salon selection).
                        Navigator.of(context).pushNamed('/booking/select-salon');
                      },
                      child: const Text('Jetzt buchen'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
