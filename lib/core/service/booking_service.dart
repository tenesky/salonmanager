import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:multiplat/core/model/booking.dart';

/// Service responsible for appointment bookings.
///
/// This service talks to the PHP backend to retrieve available slots,
/// create new bookings and fetch a customer's existing bookings. It does
/// not embed any UI logic and can be used from view models or
/// directly inside a view.
class BookingService {
  /// Base URL of the PHP API. Adjust to your deployment. Must not
  /// include a trailing slash.
  final String baseUrl = 'https://api-4people.3g-hosting.de';

  /// Returns a list of available time slots (as ISO datetime strings)
  /// for the given [serviceId], [employeeId] and [date] (YYYY-MM-DD).
  /// Each entry in the returned list represents a start time. If an
  /// error occurs, an empty list is returned.
  Future<List<String>> getAvailableSlots(int serviceId, int employeeId, String date) async {
    final uri = Uri.parse('$baseUrl/get_available_slots.php');
    try {
      final response = await http.post(uri, body: {
        'service_id': serviceId.toString(),
        'employee_id': employeeId.toString(),
        'date': date,
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['success'] == true && decoded['slots'] is List) {
          return (decoded['slots'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      // ignore errors, return empty list
    }
    return <String>[];
  }

  /// Creates a new booking for the specified customer, employee and
  /// service. Requires the start and end datetime (ISO strings).
  /// Returns true if the operation succeeded. If a conflict is
  /// detected or an error occurs, false is returned.
  Future<bool> createBooking({
    required int customerId,
    required int employeeId,
    required int serviceId,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) async {
    final uri = Uri.parse('$baseUrl/create_booking.php');
    try {
      final response = await http.post(uri, body: {
        'customer_id': customerId.toString(),
        'employee_id': employeeId.toString(),
        'service_id': serviceId.toString(),
        'start_datetime': startDateTime.toIso8601String(),
        'end_datetime': endDateTime.toIso8601String(),
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

  /// Fetches all bookings for a given [customerId]. The backend
  /// returns a list of bookings with service and employee names
  /// included. Returns an empty list on error.
  Future<List<Booking>> fetchCustomerBookings(int customerId) async {
    final uri = Uri.parse('$baseUrl/get_customer_bookings.php?customer_id=$customerId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['success'] == true && decoded['bookings'] is List) {
          return (decoded['bookings'] as List)
              .map((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      // ignore errors
    }
    return <Booking>[];
  }
}