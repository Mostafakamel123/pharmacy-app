/// Pharmacy model with location and availability data
class PharmacyModel {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final double distance; // in km
  final bool isOpen;
  final double rating;
  final String phone;
  final String imageUrl;
  final bool isPriority; // For priority pharmacies
  final int estimatedResponseTime; // in seconds

  PharmacyModel({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.isOpen,
    required this.rating,
    required this.phone,
    required this.imageUrl,
    this.isPriority = false,
    this.estimatedResponseTime = 180,
  });

  PharmacyModel copyWith({
    String? id,
    String? name,
    String? location,
    double? latitude,
    double? longitude,
    double? distance,
    bool? isOpen,
    double? rating,
    String? phone,
    String? imageUrl,
    bool? isPriority,
    int? estimatedResponseTime,
  }) {
    return PharmacyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      isOpen: isOpen ?? this.isOpen,
      rating: rating ?? this.rating,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      isPriority: isPriority ?? this.isPriority,
      estimatedResponseTime:
          estimatedResponseTime ?? this.estimatedResponseTime,
    );
  }

  @override
  String toString() =>
      'PharmacyModel(id: $id, name: $name, distance: ${distance}km)';
}
