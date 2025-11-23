import 'dart:convert';

/// A model representing a salon service offered by 4people.
///
/// Each service has a name, a duration in minutes, an optional price
/// and an optional buffer in minutes that is automatically added
/// after the service (e.g. for cleaning up). The [id] is assigned
/// by the backend.
class Service {
  final int id;
  final String name;
  final int durationMinutes;
  final double price;
  final int bufferMinutes;

  Service({
    required this.id,
    required this.name,
    required this.durationMinutes,
    this.price = 0,
    this.bufferMinutes = 0,
  });

  /// Creates a [Service] instance from a JSON map. Expects keys
  /// `id`, `name`, `duration_minutes`, `price` and `buffer_minutes`.
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes']
          : int.parse(json['duration_minutes'].toString()),
      price: json['price'] != null
          ? (json['price'] is num
              ? (json['price'] as num).toDouble()
              : double.tryParse(json['price'].toString()) ?? 0)
          : 0,
      bufferMinutes: json['buffer_minutes'] != null
          ? (json['buffer_minutes'] is int
              ? json['buffer_minutes']
              : int.tryParse(json['buffer_minutes'].toString()) ?? 0)
          : 0,
    );
  }

  /// Converts this [Service] into a JSON map. Useful for sending
  /// updates back to the API. Note that this does not include [id]
  /// by default.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration_minutes': durationMinutes,
      'price': price,
      'buffer_minutes': bufferMinutes,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}