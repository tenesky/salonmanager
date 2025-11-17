import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../common/themed_background.dart';
import '../../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registration screen for new customers.
///
/// This form collects first name, last name, email and password.  After
/// sign‑up an OTP is sent via email to complete two‑factor
/// authentication.  Additional fields (e.g. marketing opt‑in) can be
/// easily added.
class RegisterCustomerPage extends StatefulWidget {
  const RegisterCustomerPage({Key? key}) : super(key: key);

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _acceptMarketing = false;
  bool _loading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _loading = true;
    });
    try {
      // Register the user using email/password. Names are collected but
      // not yet persisted. This will throw if the email already exists.
      await AuthService.signUpWithPassword(email: email, password: password);
      // Attempt to send a 6‑digit code. Even if sending fails, we
      // continue to the next page so the user can request a new code.
      bool otpSent = false;
      try {
        await AuthService.sendOtpForExistingUser(email);
        otpSent = true;
      } catch (_) {
        // ignore OTP error
      }
      if (!mounted) return;
      if (otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrierungs‑Code gesendet. Bitte prüfen Sie Ihre E‑Mail.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrierung erfolgreich. Code konnte nicht gesendet werden.')),
        );
      }
      // Pass the user role so the two‑factor page knows which onboarding
      // flow to show after verification. Customers use the shorter
      // onboarding, salon owners use the extended version. Here we
      // explicitly set the role to `customer`.
      // Persist the first name locally so we can greet the user on the
      // home screen. Storing this in SharedPreferences allows
      // retrieval after onboarding. We ignore any errors here.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile.firstName', _firstNameController.text.trim());
      } catch (_) {}
      Navigator.of(context).pushNamed('/two-factor', arguments: {
        'email': email,
        'role': 'customer',
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Registrierung: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      // Remove the default app bar for a clean, full‑screen sign up page.
      body: ThemedBackground(
        child: Container(
          // Ensure the colour overlay covers the entire screen so the patterned
          // background remains visible even below the scrollable content. Without
          // specifying width/height, the container may shrink to its child,
          // leaving an empty area at the bottom where the pattern disappears.
          width: double.infinity,
          height: double.infinity,
          color: brightness == Brightness.dark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.6),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Title and subtitle
                    Text(
                      'Sign up',
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create an account to get started',
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Name field
                    TextFormField(
                      controller: _firstNameController,
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Name',
                        hintStyle: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                        filled: true,
                        fillColor: brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: accent,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Namen eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                        filled: true,
                        fillColor: brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: accent,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte E‑Mail eingeben';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Ungültige E‑Mail‑Adresse';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Create a password',
                        hintStyle: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                        filled: true,
                        fillColor: brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: accent,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Passwort eingeben';
                        }
                        if (value.length < 6) {
                          return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Confirm password',
                        hintStyle: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                        filled: true,
                        fillColor: brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: accent,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Passwort bestätigen';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwörter stimmen nicht überein';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Terms and privacy policy agreement
                    RichText(
                      text: TextSpan(
                        text: 'I\'ve read and agree with the ',
                        style: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Terms & Conditions coming soon…')),
                                );
                              },
                          ),
                          TextSpan(
                            text: ' and the ',
                            style: TextStyle(
                              color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Privacy Policy coming soon…')),
                                );
                              },
                          ),
                          TextSpan(
                            text: '.',
                            style: TextStyle(
                              color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sign up button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 16),
                    // Already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
