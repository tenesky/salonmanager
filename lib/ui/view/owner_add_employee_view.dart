import 'package:flutter/material.dart';
import 'package:multiplat/core/viewmodel/employees_viewmodel.dart';
import 'package:multiplat/ui/view/base_view.dart';
import 'package:multiplat/core/enum/viewstate.dart';

/// A form for creating a new employee. Allows the owner to
/// input name, email and password. On successful creation, this
/// page pops with a `true` result so the previous screen can
/// refresh its list.
class OwnerAddEmployeeView extends StatefulWidget {
  const OwnerAddEmployeeView({super.key});

  @override
  State<OwnerAddEmployeeView> createState() => _OwnerAddEmployeeViewState();
}

class _OwnerAddEmployeeViewState extends State<OwnerAddEmployeeView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<EmployeesViewModel>(
      onModelReady: (model) {},
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mitarbeiter hinzufügen'),
          ),
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
                          return 'Bitte den Namen eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-Mail'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte die E-Mail eingeben';
                        }
                        if (!value.contains('@')) {
                          return 'Bitte eine gültige E-Mail eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Passwort'),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Passwort muss mindestens 6 Zeichen enthalten';
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: model.state == ViewState.Busy
                                ? null
                                : () async {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      final name = _nameController.text.trim();
                                      final email = _emailController.text.trim();
                                      final password = _passwordController.text;
                                      final success = await model.createEmployee(name, email, password);
                                      if (success) {
                                        if (!context.mounted) return;
                                        Navigator.pop(context, true);
                                      } else {
                                        setState(() {
                                          _error = 'Erstellung fehlgeschlagen';
                                        });
                                      }
                                    }
                                  },
                            child: model.state == ViewState.Busy
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : const Text('Speichern'),
                          ),
                        ),
                      ],
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