import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:multiplat/core/model/service.dart';

/// Service responsible for CRUD operations related to salon services.
/// Communicates with the PHP backend to fetch, add, update and delete
/// services. The baseUrl should be set to the API root without a
/// trailing slash.
class ServiceService {
  final String baseUrl = 'https://api-4people.3g-hosting.de';

  /// Fetches all services from the backend. Returns an empty list if
  /// an error occurs.
  Future<List<Service>> fetchServices() async {
    final uri = Uri.parse('$baseUrl/get_services.php');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['success'] == true && decoded['services'] is List) {
          return (decoded['services'] as List)
              .map((e) => Service.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      // ignore errors
    }
    return <Service>[];
  }

  /// Adds a new service with the given parameters. Returns true if
  /// successful.
  Future<bool> addService(String name, int durationMinutes, double price, int bufferMinutes) async {
    final uri = Uri.parse('$baseUrl/add_service.php');
    try {
      final response = await http.post(uri, body: {
        'name': name,
        'duration_minutes': durationMinutes.toString(),
        'price': price.toString(),
        'buffer_minutes': bufferMinutes.toString(),
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is Map && decoded['success'] == true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  /// Updates an existing service. Returns true if the operation
  /// succeeded. All parameters are required.
  Future<bool> updateService(Service service) async {
    final uri = Uri.parse('$baseUrl/update_service.php');
    try {
      final response = await http.post(uri, body: {
        'id': service.id.toString(),
        'name': service.name,
        'duration_minutes': service.durationMinutes.toString(),
        'price': service.price.toString(),
        'buffer_minutes': service.bufferMinutes.toString(),
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is Map && decoded['success'] == true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  /// Deletes a service by its ID. Returns true if the deletion was
  /// successful.
  Future<bool> deleteService(int id) async {
    final uri = Uri.parse('$baseUrl/delete_service.php');
    try {
      final response = await http.post(uri, body: {'id': id.toString()});
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is Map && decoded['success'] == true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }
}