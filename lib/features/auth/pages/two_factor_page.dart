import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../common/themed_background.dart';

/// A page that prompts the user to enter the six‑digit two‑factor
/// authentication code sent via email. The design follows the
/// provided mockup: a dark patterned background with a translucent
/// overlay, a headline and subtitle, six individual input boxes, a
/// “Resend code” link and a yellow "Continue" button. Each
/// character is entered into its own box; focus automatically
/// advances as the user types and moves backwards on deletion. The
/// page reads the `email` and `role` from the route arguments. On
/// successful verification it navigates to the appropriate
/// onboarding flow: customers go directly to the customer
/// onboarding, while salon owners first complete the personal
/// onboarding and then their business details.
class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({Key? key}) : super(key: key);

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  // Controllers and focus nodes for the six digit inputs.
  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List<FocusNode>.generate(6, (_) => FocusNode());

  String? _email;
  String _role = 'customer';
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Extract email and role from route arguments. Only set once.
    if (_email == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        if (args['email'] is String) {
          _email = args['email'] as String;
        }
        if (args['role'] is String) {
          _role = args['role'] as String;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Whether all six fields have exactly one character entered.
  bool get _isComplete {
    for (final controller in _controllers) {
      if (controller.text.trim().isEmpty) return false;
    }
    return true;
  }

  /// Resend the code to the stored email address. If no email is
  /// available, show an error. Uses the same endpoint as initial
  /// sending.
  Future<void> _resendCode() async {
    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine E‑Mail‑Adresse vorhanden.')),
      );
      return;
    }
    try {
      await AuthService.sendOtpForExistingUser(_email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code erneut gesendet.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Senden des Codes: $error')),
      );
    }
  }

  /// Concatenate the six digits into a single string.
  String _collectCode() {
    final buffer = StringBuffer();
    for (final controller in _controllers) {
      buffer.write(controller.text.trim());
    }
    return buffer.toString();
  }

  /// Verify the entered code via the AuthService. On success,
  /// navigate to the appropriate onboarding flow. On failure,
  /// display an error. The button is disabled while `_loading` is true.
  Future<void> _verifyCode() async {
    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine E‑Mail‑Adresse vorhanden.')),
      );
      return;
    }
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte den 6‑stelligen Code vollständig eingeben.')),
      );
      return;
    }
    final code = _collectCode();
    setState(() {
      _loading = true;
    });
    try {
      final success = await AuthService.verifyOtp(email: _email!, code: code);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erfolgreich angemeldet.')),
        );
        // Navigate to the appropriate onboarding flow based on role. We
        // remove all previous routes so the user cannot go back to
        // the 2FA page.
        if (_role == 'salon') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/onboarding-customer',
            (route) => false,
            arguments: {'role': 'salon'},
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/onboarding-customer',
            (route) => false,
            arguments: {'role': 'customer'},
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ungültiger Code.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Überprüfen des Codes: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Build a single digit input box. The [index] determines which
  /// controller and focus node to use. On input, focus advances
  /// automatically; on deletion, focus moves back.
  Widget _buildDigitField(int index) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return SizedBox(
      width: 48,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
        maxLength: 1,
        cursorColor: accent,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1) {
            if (index < _focusNodes.length - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = theme.colorScheme.secondary;
    return Scaffold(
      // Transparent app bar with back navigation. Even though the mockup
      // doesn’t show a back button, we include one to allow the user to
      // return to the previous page (e.g. registration or login) if
      // necessary. You may remove this if not desired.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: brightness == Brightness.dark ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ThemedBackground(
        child: Container(
          color: brightness == Brightness.dark
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.4),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Enter confirmation code',
                    style: TextStyle(
                      color: brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                    const SizedBox(height: 8),
                  Text(
                    _email != null
                        ? 'A 6‑digit code was sent to\n${_email!}'
                        : 'A 6‑digit code was sent to your email',
                    style: TextStyle(
                      color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Row of six boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildDigitField(index)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _resendCode,
                        child: Text(
                          'Resend code',
                          style: TextStyle(color: accent),
                        ),
                      ),
                      // Placeholder for possible recovery options
                      const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading || !_isComplete ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}