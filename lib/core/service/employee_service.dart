import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:multiplat/core/model/employee.dart';
import 'package:multiplat/locator.dart';
import 'package:multiplat/core/service/auth_service.dart';
import 'package:multiplat/core/util/multiplat_shared_prefs.dart';

/// Service responsible for CRUD operations related to employees.
///
/// This service communicates with the PHP backend to retrieve and
/// manipulate employee data. It exposes methods for fetching all
/// employees, deleting an employee, updating employee details and
/// optionally creating new employees via the [AuthService].
class EmployeeService {
  /// The base URL of the PHP API. Should include the protocol and
  /// domain name but not the trailing slash. For example:
  /// `https://api-4people.3g-hosting.de`.
  final String baseUrl = 'https://api-4people.3g-hosting.de';

  /// Returns a list of [Employee] objects representing all employees in
  /// the system. Employees are defined as users with the role
  /// 'employee'. If an error occurs or the request fails, an empty
  /// list is returned.
  Future<List<Employee>> fetchEmployees() async {
    final uri = Uri.parse('$baseUrl/get_employees.php');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['success'] == true && decoded['employees'] is List) {
          return (decoded['employees'] as List)
              .map((e) => Employee.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      // ignore errors; return empty list below
    }
    return <Employee>[];
  }

  /// Deletes the employee with the given [id]. Only employees (role
  /// 'employee') should be deleted via this endpoint. Returns `true`
  /// if the operation succeeded, otherwise `false`.
  Future<bool> deleteEmployee(int id) async {
    final uri = Uri.parse('$baseUrl/delete_employee.php');
    try {
      final response = await http.post(uri, body: {
        'id': id.toString(),
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is Map && decoded['success'] == true;
      }
    } catch (e) {
      // ignore errors
    }
    return false;
  }

  /// Updates the given [employee] on the server. This method only
  /// updates the name and email fields; role and password are
  /// intentionally not changed here. Returns `true` on success.
  Future<bool> updateEmployee(Employee employee) async {
    final uri = Uri.parse('$baseUrl/update_employee.php');
    try {
      final response = await http.post(uri, body: {
        'id': employee.id.toString(),
        'name': employee.name,
        'email': employee.email,
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is Map && decoded['success'] == true;
      }
    } catch (e) {
      // ignore errors
    }
    return false;
  }

  /// Creates a new employee using the AuthService's registration flow.
  /// This helper simply calls [AuthService.register] with the role
  /// 'employee'. Returns `true` if registration succeeded.
  Future<bool> createEmployee(String name, String email, String password) async {
    final authService = locator<AuthService>();
    return await authService.register(name, email, password, 'employee');
  }
}