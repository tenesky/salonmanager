import 'package:multiplat/core/model/service.dart';
import 'package:multiplat/core/service/service_service.dart';
import 'package:multiplat/core/viewmodel/base_viewmodel.dart';
import 'package:multiplat/locator.dart';

/// ViewModel to manage the list of services. Provides methods to
/// fetch all services and to add, update or delete a service via
/// [ServiceService]. Extends [BaseViewModel] to expose loading
/// state.
class ServicesViewModel extends BaseViewModel {
  final ServiceService _serviceService = locator<ServiceService>();

  List<Service> _services = [];
  String? _error;

  List<Service> get services => _services;
  String? get error => _error;

  /// Loads services from the backend. Updates the loading state and
  /// error message accordingly.
  Future<void> fetchServices() async {
    setBusy();
    _error = null;
    try {
      final list = await _serviceService.fetchServices();
      _services = list;
    } catch (e) {
      _error = 'Konnte Services nicht laden';
      _services = [];
    } finally {
      setIdle();
    }
  }

  /// Adds a new service. On success, refreshes the service list.
  Future<bool> addService(String name, int durationMinutes, double price, int bufferMinutes) async {
    setBusy();
    final success = await _serviceService.addService(name, durationMinutes, price, bufferMinutes);
    if (success) {
      await fetchServices();
    }
    return success;
  }

  /// Updates an existing service. On success, refreshes the service list.
  Future<bool> updateService(Service service) async {
    setBusy();
    final success = await _serviceService.updateService(service);
    if (success) {
      await fetchServices();
    }
    return success;
  }

  /// Deletes a service by ID. On success, refreshes the list.
  Future<bool> deleteService(int id) async {
    setBusy();
    final success = await _serviceService.deleteService(id);
    if (success) {
      await fetchServices();
    }
    return success;
  }
}