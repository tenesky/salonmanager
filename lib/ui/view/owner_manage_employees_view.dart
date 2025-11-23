import 'package:flutter/material.dart';
import 'package:multiplat/core/model/employee.dart';
import 'package:multiplat/core/viewmodel/employees_viewmodel.dart';
import 'package:multiplat/core/enum/viewstate.dart';
import 'package:multiplat/ui/view/owner_add_employee_view.dart';
import 'package:multiplat/ui/view/owner_edit_employee_view.dart';
import 'package:multiplat/ui/view/base_view.dart';

/// Screen for managing employees. Allows the salon owner or admin to
/// view the list of employees, add new employees, edit existing ones
/// and delete employees from the system. Uses [EmployeesViewModel]
/// to fetch and modify employee data via the backend API.
class OwnerManageEmployeesView extends StatelessWidget {
  const OwnerManageEmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseView<EmployeesViewModel>(
      onModelReady: (model) => model.fetchEmployees(),
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mitarbeiter verwalten'),
          ),
          body: _buildBody(context, model),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              // Navigate to add employee page. When the page returns true,
              // refresh the list.
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const OwnerAddEmployeeView(),
                ),
              );
              if (result == true) {
                await model.fetchEmployees();
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, EmployeesViewModel model) {
    if (model.state == ViewState.Busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (model.error != null) {
      return Center(child: Text(model.error!));
    }
    final employees = model.employees;
    if (employees.isEmpty) {
      return const Center(
        child: Text('Keine Mitarbeiter gefunden. Tippen Sie auf +, um einen neuen Mitarbeiter hinzuzufügen.'),
      );
    }
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return ListTile(
          title: Text(employee.name),
          subtitle: Text(employee.email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Bearbeiten',
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerEditEmployeeView(employee: employee),
                    ),
                  );
                  if (result == true) {
                    await model.fetchEmployees();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Löschen',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Mitarbeiter löschen?'),
                        content: Text('Möchten Sie ${employee.name} wirklich entfernen?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Abbrechen'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Löschen'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    await model.deleteEmployee(employee.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mitarbeiter wurde gelöscht')), 
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}