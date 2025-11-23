import 'package:flutter/material.dart';
import 'package:multiplat/core/model/employee.dart';
import 'package:multiplat/core/viewmodel/employees_viewmodel.dart';
import 'package:multiplat/ui/view/base_view.dart';
import 'package:multiplat/core/enum/viewstate.dart';

/// A screen for editing an existing employee's basic information.
/// Allows modification of the name and email. Does not provide a way
/// to change the role or password at this time. On successful
/// update, this page pops with a `true` result so the previous
/// screen can refresh its list.
class OwnerEditEmployeeView extends StatefulWidget {
  final Employee employee;
  const OwnerEditEmployeeView({super.key, required this.employee});

  @override
  State<OwnerEditEmployeeView> createState() => _OwnerEditEmployeeViewState();
}

class _OwnerEditEmployeeViewState extends State<OwnerEditEmployeeView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _emailController = TextEditingController(text: widget.employee.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<EmployeesViewModel>(
      onModelReady: (model) {},
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.employee.name} bearbeiten'),
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
                                      final updatedEmployee = Employee(
                                        id: widget.employee.id,
                                        name: _nameController.text.trim(),
                                        email: _emailController.text.trim(),
                                        role: widget.employee.role,
                                      );
                                      final success = await model.updateEmployee(updatedEmployee);
                                      if (success) {
                                        if (!context.mounted) return;
                                        Navigator.pop(context, true);
                                      } else {
                                        setState(() {
                                          _error = 'Aktualisierung fehlgeschlagen';
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