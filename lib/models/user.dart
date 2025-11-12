/// Represents a logged in user.  The backend returns a subset of
/// user properties which are mapped into this model.  Additional
/// fields (first and last name) are optional because the sample
/// backend does not currently return them for all endpoints.
class User {
  final int id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }
}