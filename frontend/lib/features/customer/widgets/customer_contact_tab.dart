import 'package:flutter/material.dart';
import '../../../services/db_service.dart';

/// A tab for editing a customer's contact details and marketing opt‑in.
///
/// Displays text fields for E‑Mail und Telefon sowie einen Schalter
/// für das Marketing‑Einverständnis. Beim Speichern wird die
/// Datenbank über [DbService.updateCustomerContact] aktualisiert und
/// eine kurze Bestätigung angezeigt. Felder, die nicht geändert
/// wurden, bleiben unberührt.
class CustomerContactTab extends StatefulWidget {
  final int customerId;
  final String? initialEmail;
  final String? initialPhone;
  final bool initialMarketingOptIn;
  const CustomerContactTab({
    Key? key,
    required this.customerId,
    this.initialEmail,
    this.initialPhone,
    this.initialMarketingOptIn = false,
  }) : super(key: key);

  @override
  State<CustomerContactTab> createState() => _CustomerContactTabState();
}

class _CustomerContactTabState extends State<CustomerContactTab> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late bool _marketingOptIn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _marketingOptIn = widget.initialMarketingOptIn;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Saves the updated contact information to the database. Only
  /// fields that differ from the initial values are sent. Shows
  /// success or error feedback via a SnackBar.
  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    final updates = <String, dynamic>{};
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (email != (widget.initialEmail ?? '')) {
      updates['email'] = email.isNotEmpty ? email : null;
    }
    if (phone != (widget.initialPhone ?? '')) {
      updates['phone'] = phone.isNotEmpty ? phone : null;
    }
    if (_marketingOptIn != widget.initialMarketingOptIn) {
      updates['marketingOptIn'] = _marketingOptIn;
    }
    try {
      if (updates.isNotEmpty) {
        await DbService.updateCustomerContact(
          id: widget.customerId,
          email: updates.containsKey('email') ? updates['email'] as String? : null,
          phone: updates.containsKey('phone') ? updates['phone'] as String? : null,
          marketingOptIn:
              updates.containsKey('marketingOptIn') ? updates['marketingOptIn'] as bool : null,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kontaktinformationen gespeichert')), 
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Speichern')), 
        );
      }
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E‑Mail',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            title: const Text('Newsletter-Einverständnis'),
            value: _marketingOptIn,
            onChanged: (val) {
              setState(() {
                _marketingOptIn = val;
              });
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
          ),
        ],
      ),
    );
  }
}