import 'dart:convert';

/// A model representing an appointment booking.
///
/// Each booking ties together a customer, an employee and a service at a
/// specific time window. The [startDateTime] and [endDateTime] are in
/// local time and represent the actual appointment duration. The
/// [status] indicates if the booking is confirmed or has been
/// cancelled/rescheduled. Optional [serviceName] and [employeeName]
/// fields are provided when the backend joins related tables for
/// convenience.
class Booking {
  final int id;
  final int customerId;
  final int employeeId;
  final int serviceId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String status;
  final String? serviceName;
  final String? employeeName;

  Booking({
    required this.id,
    required this.customerId,
    required this.employeeId,
    required this.serviceId,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
    this.serviceName,
    this.employeeName,
  });

  /// Creates a [Booking] instance from a JSON map. Expects keys
  /// matching the DB column names. If `service_name` or
  /// `employee_name` are present, they will be assigned to the
  /// optional fields.
  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }
    return Booking(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      customerId: json['customer_id'] is int
          ? json['customer_id']
          : int.parse(json['customer_id'].toString()),
      employeeId: json['employee_id'] is int
          ? json['employee_id']
          : int.parse(json['employee_id'].toString()),
      serviceId: json['service_id'] is int
          ? json['service_id']
          : int.parse(json['service_id'].toString()),
      startDateTime: parseDate(json['start_datetime']),
      endDateTime: parseDate(json['end_datetime']),
      status: json['status']?.toString() ?? 'confirmed',
      serviceName: json['service_name']?.toString(),
      employeeName: json['employee_name']?.toString(),
    );
  }

  /// Serializes this booking into a JSON map. Useful when sending
  /// booking data back to the API. Note that optional fields like
  /// [serviceName] and [employeeName] are not included by default.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'employee_id': employeeId,
      'service_id': serviceId,
      'start_datetime': startDateTime.toIso8601String(),
      'end_datetime': endDateTime.toIso8601String(),
      'status': status,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}