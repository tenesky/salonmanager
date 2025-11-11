import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seventh step of the booking wizard: payment.
///
/// This screen allows customers to choose between paying a deposit or
/// the full amount and select a payment method (Karte, Wallet,
/// Bar). Users must also accept the general terms and conditions
/// (AGB) and the privacy policy before proceeding. The selection
/// will be stored in shared preferences so that the booking draft
/// persists across sessions. This page fulfils the requirements of
/// Screen 22【522868310347694†L169-L174】.
class BookingPaymentPage extends StatefulWidget {
  const BookingPaymentPage({Key? key}) : super(key: key);

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  String _paymentType = 'anzahlung';
  String? _paymentMethod;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('draft_payment_type');
    final method = prefs.getString('draft_payment_method');
    final terms = prefs.getBool('draft_payment_terms');
    setState(() {
      _paymentType = type ?? 'anzahlung';
      _paymentMethod = method;
      _acceptedTerms = terms ?? false;
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_payment_type', _paymentType);
    if (_paymentMethod != null) {
      await prefs.setString('draft_payment_method', _paymentMethod!);
    }
    await prefs.setBool('draft_payment_terms', _acceptedTerms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zahlung'),
      ),
      body: Column(
        children: [
          // Step indicator 7/8
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 7 / 8,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('7/8'),
              ],
            ),
          ),
          // Payment type selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zahlungsbetrag',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ToggleButtons(
                  isSelected: [_paymentType == 'anzahlung', _paymentType == 'voll'],
                  onPressed: (index) {
                    setState(() {
                      _paymentType = index == 0 ? 'anzahlung' : 'voll';
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Anzahlung'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Komplett'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Payment method selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zahlungsmethode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildPaymentMethodChip('karte', 'Karte'),
                    _buildPaymentMethodChip('wallet', 'Wallet'),
                    _buildPaymentMethodChip('bar', 'Bar'),
                  ],
                ),
              ],
            ),
          ),
          // Terms and conditions checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: CheckboxListTile(
              value: _acceptedTerms,
              onChanged: (value) {
                setState(() {
                  _acceptedTerms = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              title: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Ich akzeptiere die '),
                    TextSpan(
                      text: 'AGB',
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                    const TextSpan(text: ' und die '),
                    TextSpan(
                      text: 'Datenschutzerklärung',
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: (_paymentMethod != null && _acceptedTerms)
              ? () async {
                  await _saveDraft();
                  Navigator.of(context).pushNamed('/booking/summary');
                }
              : null,
          child: const Text('Weiter'),
        ),
      ),
    );
  }

  /// Builds a chip for selecting a payment method.
  Widget _buildPaymentMethodChip(String method, String label) {
    final bool isSelected = _paymentMethod == method;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _paymentMethod = method;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
    );
  }
}