import 'package:flutter/material.dart';
import '../models/salon.dart';

/// Detail view for a salon. Displays basic information about the salon
/// and provides a quick booking option via a bottom sheet. The
/// bottom sheet contains a mini‑calendar and a time slot picker, and
/// a CTA that navigates to the booking wizard step 1. This
/// corresponds to the „Salon‑Schnellwahl“ screen (Modul B, Screen 14).
class SalonDetailPage extends StatefulWidget {
  final Salon salon;

  const SalonDetailPage({Key? key, required this.salon}) : super(key: key);

  @override
  State<SalonDetailPage> createState() => _SalonDetailPageState();
}

class _SalonDetailPageState extends State<SalonDetailPage> {
  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;
    return Scaffold(
      appBar: AppBar(
        title: Text(salon.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image with logo overlay
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Start the booking wizard directly. We begin at the
                      // salon selection step so the user can confirm or change
                      // their selection. In a future iteration this could
                      // pre‑select the current salon and skip that step.
                      onPressed: () {
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

  /// Opens a bottom sheet allowing the user to quickly select a date
  /// and time for a booking. Once both a day and a time are chosen,
  /// the "Zum Booking‑Wizard" button navigates to the first step of
  /// the booking process. This implements the mini‑calendar and
  /// timeslot picker required for Screen 14. For now the wizard page
  /// is a placeholder.
  // The quick booking bottom sheet has been removed. Booking now always starts
  // at the full booking wizard (salon selection). This stub remains for
  // compatibility but does nothing.
  void _openQuickBooking() {}
}