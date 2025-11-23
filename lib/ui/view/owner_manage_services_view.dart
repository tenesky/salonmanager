import 'package:flutter/material.dart';
import 'package:multiplat/core/enum/viewstate.dart';
import 'package:multiplat/core/model/service.dart';
import 'package:multiplat/core/viewmodel/services_viewmodel.dart';
import 'package:multiplat/ui/view/base_view.dart';
import 'package:multiplat/ui/view/owner_add_service_view.dart';
import 'package:multiplat/ui/view/owner_edit_service_view.dart';

/// View that displays a list of salon services and allows the owner
/// to create, edit and remove services. Each service entry shows
/// the name and duration. When a service is selected, the admin
/// can edit its details or delete it.
class OwnerManageServicesView extends StatelessWidget {
  const OwnerManageServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseView<ServicesViewModel>(
      onModelReady: (model) => model.fetchServices(),
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Services verwalten'),
          ),
          body: _buildBody(context, model),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const OwnerAddServiceView()),
              );
              if (result == true) {
                await model.fetchServices();
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ServicesViewModel model) {
    if (model.state == ViewState.Busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (model.error != null) {
      return Center(child: Text(model.error!));
    }
    final services = model.services;
    if (services.isEmpty) {
      return const Center(
        child: Text('Keine Services vorhanden. Tippen Sie auf +, um einen Service hinzuzufügen.'),
      );
    }
    return ListView.separated(
      itemCount: services.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final service = services[index];
        return ListTile(
          title: Text(service.name),
          subtitle: Text('Dauer: ${service.durationMinutes} Min.\nPuffer: ${service.bufferMinutes} Min.'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerEditServiceView(service: service),
                    ),
                  );
                  if (result == true) {
                    await model.fetchServices();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Service löschen?'),
                      content: Text('Möchten Sie den Service ${service.name} wirklich löschen?'),
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
                    ),
                  );
                  if (confirm == true) {
                    final success = await model.deleteService(service.id);
                    if (success) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Service gelöscht')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Löschen fehlgeschlagen')),
                      );
                    }
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