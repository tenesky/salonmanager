import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';

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
  // Payment type: 'anzahlung' or 'voll'
  String _paymentType = 'anzahlung';
  // Payment method: 'online', 'bar' or 'rechnung'
  String _paymentMethod = 'online';
  // Deposit amount when anzahlung is selected
  final TextEditingController _depositController = TextEditingController();
  bool _acceptedTerms = false;

  /// Builds the persistent bottom navigation bar used throughout the app.
  /// [currentIndex] indicates the active tab. For booking pages we use index 2.
  Widget _buildBottomNav(BuildContext context, {required int currentIndex}) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: accent,
      unselectedItemColor:
          brightness == Brightness.dark ? Colors.white70 : Colors.black54,
      backgroundColor:
          brightness == Brightness.dark ? Colors.black : Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Galerie'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Buchen'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Termine'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            break;
          case 1:
            Navigator.of(context).pushNamed('/gallery');
            break;
          case 2:
            Navigator.of(context).pushNamed('/booking/select-salon');
            break;
          case 3:
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/profile/bookings');
            }
            break;
          case 4:
            if (!AuthService.isLoggedIn()) {
              Navigator.of(context).pushNamed('/login');
            } else {
              Navigator.of(context).pushNamed('/settings/profile');
            }
            break;
        }
      },
    );
  }

  /// Returns whether the current payment selection is valid.  For
  /// bar payments no further input is required.  For online or
  /// invoice payments the deposit amount must be provided if
  /// `anzahlung` is selected.
  bool _isValidSelection() {
    if (_paymentMethod == 'bar') {
      return true;
    }
    if (_paymentType == 'anzahlung') {
      return _depositController.text.trim().isNotEmpty;
    }
    return true;
  }

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
    final deposit = prefs.getString('draft_payment_deposit');
    setState(() {
      _paymentType = type ?? 'anzahlung';
      _paymentMethod = method ?? 'online';
      _acceptedTerms = terms ?? false;
      if (deposit != null) {
        _depositController.text = deposit;
      }
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_payment_type', _paymentType);
    await prefs.setString('draft_payment_method', _paymentMethod);
    await prefs.setBool('draft_payment_terms', _acceptedTerms);
    if (_paymentType == 'anzahlung' && _paymentMethod != 'bar') {
      await prefs.setString('draft_payment_deposit', _depositController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zahlung'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
          // Payment method selection (Online, Bar, Rechnung)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zahlungsart',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Column(
                  children: [
                    RadioListTile<String>(
                      value: 'online',
                      groupValue: _paymentMethod,
                      title: const Text('Online (Karte/Wallet)'),
                      subtitle: const Text('Bezahlen Sie bequem per Karte oder Wallet vorab.'),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      value: 'bar',
                      groupValue: _paymentMethod,
                      title: const Text('Barzahlung vor Ort'),
                      subtitle: const Text('Zahlung erfolgt im Salon bei Terminbeginn.'),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      value: 'rechnung',
                      groupValue: _paymentMethod,
                      title: const Text('Rechnung'),
                      subtitle: const Text('Sie erhalten eine Rechnung per E-Mail nach dem Termin.'),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Payment type selection (only relevant if not bar)
          if (_paymentMethod != 'bar')
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
          // Deposit amount input (only show if Anzahlung selected and method is not bar)
          if (_paymentMethod != 'bar' && _paymentType == 'anzahlung')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: TextField(
                controller: _depositController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Anzahlungsbetrag (€)',
                  border: OutlineInputBorder(),
                ),
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
          // Continue button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _acceptedTerms && _isValidSelection()
                    ? () async {
                        await _saveDraft();
                        Navigator.of(context).pushNamed('/booking/summary');
                      }
                    : null,
                child: const Text('Weiter'),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: _buildBottomNav(context, currentIndex: 2),
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

  @override
  void dispose() {
    _depositController.dispose();
    super.dispose();
  }
}