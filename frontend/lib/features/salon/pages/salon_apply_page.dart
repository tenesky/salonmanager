import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Page allowing salon owners to submit their salon for approval.
///
/// This form collects basic details about the salon including its name,
/// address, contact information, a description and an optional logo
/// image. When the form is submitted a simple confirmation message
/// is shown. At a later stage this data can be sent to Supabase to
/// create a new entry in the `salon_applications` table.
class SalonApplyPage extends StatefulWidget {
  const SalonApplyPage({Key? key}) : super(key: key);

  @override
  _SalonApplyPageState createState() => _SalonApplyPageState();
}

class _SalonApplyPageState extends State<SalonApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _logoImage;

  /// Picks a logo image from the gallery. If the user cancels the
  /// picker the current selection remains unchanged. Errors are
  /// silently ignored. The selected image is stored in [_logoImage].
  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _logoImage = image;
        });
      }
    } catch (_) {
      // ignore exceptions
    }
  }

  /// Handles form submission. If the form validates successfully
  /// a confirmation snackbar is displayed. In a real implementation
  /// the data would be sent to Supabase. The form fields are not
  /// cleared to allow users to revise their input if needed.
  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Danke, wir prüfen deine Anfrage')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon bewerben'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Salon‑Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte den Salon‑Namen eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte die Adresse eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E‑Mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte die E‑Mail eingeben';
                  }
                  if (!RegExp(r'^.+@.+\..+\$').hasMatch(value.trim())) {
                    return 'Ungültige E‑Mail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte eine Beschreibung eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Logo auswählen'),
                    onPressed: _pickLogo,
                  ),
                  const SizedBox(width: 16),
                  if (_logoImage != null)
                    Expanded(
                      child: Text(
                        _logoImage!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              if (_logoImage != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_logoImage!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Absenden'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}