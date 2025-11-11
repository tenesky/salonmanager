/// Simple data model representing a Salon. This model is used to
/// pass information between the salon list and detail pages. In a
/// production setting this could be generated from API models.
class Salon {
  final String name;
  final String coverImage;
  final String logoImage;
  final String address;
  final String openingHours;
  final String phone;

  const Salon({
    required this.name,
    required this.coverImage,
    required this.logoImage,
    required this.address,
    required this.openingHours,
    required this.phone,
  });
}