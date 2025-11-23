import 'package:flutter/material.dart';
import 'package:multiplat/core/enum/viewstate.dart';
import 'package:multiplat/core/model/service.dart';
import 'package:multiplat/core/viewmodel/services_viewmodel.dart';
import 'package:multiplat/ui/view/base_view.dart';

/// Form page for editing an existing service. Allows changing the
/// name, duration, price and buffer. On successful update it pops
/// with `true` so the list can refresh.
class OwnerEditServiceView extends StatefulWidget {
  final Service service;
  const OwnerEditServiceView({super.key, required this.service});

  @override
  State<OwnerEditServiceView> createState() => _OwnerEditServiceViewState();
}

class _OwnerEditServiceViewState extends State<OwnerEditServiceView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  late TextEditingController _bufferController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _durationController = TextEditingController(text: widget.service.durationMinutes.toString());
    _priceController = TextEditingController(text: widget.service.price.toString());
    _bufferController = TextEditingController(text: widget.service.bufferMinutes.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<ServicesViewModel>(
      onModelReady: (model) {},
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Service bearbeiten')), 
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte einen Namen eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(labelText: 'Dauer (Minuten)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final numVal = int.tryParse(value ?? '');
                        if (numVal == null || numVal <= 0) {
                          return 'Bitte eine gültige Dauer eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Preis (optional)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (double.tryParse(value) == null) {
                          return 'Bitte einen gültigen Preis eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bufferController,
                      decoration: const InputDecoration(labelText: 'Zeitpuffer (Minuten, optional)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final numVal = int.tryParse(value);
                        if (numVal == null || numVal < 0) {
                          return 'Bitte eine gültige Zahl eingeben';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: model.state == ViewState.Busy
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                final updated = Service(
                                  id: widget.service.id,
                                  name: _nameController.text.trim(),
                                  durationMinutes: int.parse(_durationController.text.trim()),
                                  price: _priceController.text.trim().isNotEmpty
                                      ? double.parse(_priceController.text.trim())
                                      : 0.0,
                                  bufferMinutes: _bufferController.text.trim().isNotEmpty
                                      ? int.parse(_bufferController.text.trim())
                                      : 0,
                                );
                                final success = await model.updateService(updated);
                                if (success) {
                                  if (!context.mounted) return;
                                  Navigator.pop(context, true);
                                } else {
                                  setState(() => _error = 'Service konnte nicht aktualisiert werden');
                                }
                              }
                            },
                      child: model.state == ViewState.Busy
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                          : const Text('Speichern'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}