import 'dart:convert';

/// A simple model class representing an employee (or user) in the system.
///
/// This model is used to transfer employee data between the API and the
/// Flutter application. It includes only basic information such as id,
/// name, email and role. Additional fields can be added later when
/// employee management needs to capture more details.
class Employee {
  final int id;
  final String name;
  final String email;
  final String role;

  Employee({required this.id, required this.name, required this.email, required this.role});

  /// Creates an Employee from a JSON map. Expects keys 'id', 'name',
  /// 'email' and 'role'. If any required key is missing, a [FormatException]
  /// will be thrown.
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }

  /// Converts this Employee into a JSON map. Useful for sending
  /// updates back to the API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}