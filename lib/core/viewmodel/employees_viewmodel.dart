import 'package:multiplat/core/model/employee.dart';
import 'package:multiplat/core/service/employee_service.dart';
import 'package:multiplat/core/viewmodel/base_viewmodel.dart';
import 'package:multiplat/locator.dart';

/// ViewModel for managing employees in the admin/owner interface.
///
/// This view model exposes a list of employees and methods to fetch,
/// delete and refresh that list. It uses [EmployeeService] to
/// communicate with the backend API and extends [BaseViewModel] to
/// provide loading states.
class EmployeesViewModel extends BaseViewModel {
  final EmployeeService _employeeService = locator<EmployeeService>();

  List<Employee> _employees = [];
  String? _error;

  List<Employee> get employees => _employees;
  String? get error => _error;

  /// Loads employees from the backend. Sets the state to busy while
  /// loading and updates [_employees] on success. On error,
  /// [_employees] will be empty and [_error] will contain a message.
  Future<void> fetchEmployees() async {
    setBusy();
    _error = null;
    try {
      final list = await _employeeService.fetchEmployees();
      _employees = list;
    } catch (e) {
      _error = 'Konnte Mitarbeiter nicht laden';
      _employees = [];
    } finally {
      setIdle();
    }
  }

  /// Deletes an employee with the given [id]. After deletion it
  /// refreshes the employee list. Returns `true` if the deletion was
  /// successful.
  Future<bool> deleteEmployee(int id) async {
    setBusy();
    final success = await _employeeService.deleteEmployee(id);
    await fetchEmployees();
    return success;
  }

  /// Creates a new employee using name, email and password. On
  /// success, refreshes the employee list. Returns `true` if
  /// registration succeeded.
  Future<bool> createEmployee(String name, String email, String password) async {
    setBusy();
    final success = await _employeeService.createEmployee(name, email, password);
    if (success) {
      await fetchEmployees();
    }
    return success;
  }

  /// Updates an existing employee's name and email. On success,
  /// refreshes the employee list. Returns `true` if update succeeded.
  Future<bool> updateEmployee(Employee employee) async {
    setBusy();
    final success = await _employeeService.updateEmployee(employee);
    if (success) {
      await fetchEmployees();
    }
    return success;
  }
}