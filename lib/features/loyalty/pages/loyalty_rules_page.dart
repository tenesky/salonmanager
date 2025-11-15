import 'package:flutter/material.dart';

/// A placeholder page for editing loyalty program rules.
///
/// In a full implementation this page would allow salon owners to
/// configure level thresholds and define rewards.  For now it
/// presents static content to avoid missing page errors when building
/// the app for iOS.
class LoyaltyRulesPage extends StatelessWidget {
  const LoyaltyRulesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treueprogramm verwalten'),
      ),
      body: const Center(
        child: Text('LoyaltyRulesPage (noch nicht implementiert)'),
      ),
    );
  }
}