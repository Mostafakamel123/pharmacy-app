/// User-owned pharmacy model
/// 
/// Represents a pharmacy that is owned/managed by users.
/// A user can create multiple pharmacies and assign other users as admins.
class UserPharmacyModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String coverImageUrl;
  final String ownerUserId;
  final List<String> adminUserIds;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? email;
  final String? website;
  final String? licenseNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserPharmacyModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.coverImageUrl = '',
    required this.ownerUserId,
    required this.adminUserIds,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.email,
    this.website,
    this.licenseNumber,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if a user is an admin of this pharmacy
  bool isAdmin(String userId) {
    return userId == ownerUserId || adminUserIds.contains(userId);
  }

  /// Get the list of all admin IDs (including owner)
  List<String> get allAdminIds {
    return [ownerUserId, ...adminUserIds];
  }

  /// Create a copy with updated fields
  UserPharmacyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? ownerUserId,
    List<String>? adminUserIds,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? website,
    String? licenseNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPharmacyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      adminUserIds: adminUserIds ?? this.adminUserIds,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'cover_image_url': coverImageUrl,
      'owner_user_id': ownerUserId,
      'admin_user_ids': adminUserIds,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'license_number': licenseNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON (API response)
  factory UserPharmacyModel.fromJson(Map<String, dynamic> json) {
    return UserPharmacyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String? ?? '',
      ownerUserId: json['owner_user_id'] as String,
      adminUserIds: List<String>.from(json['admin_user_ids'] ?? []),
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      licenseNumber: json['license_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Sample data for testing
  static List<UserPharmacyModel> sampleData(String currentUserId) {
    return [
      UserPharmacyModel(
        id: 'pharmacy_1',
        name: 'Al-Shifa Pharmacy',
        description: 'Your trusted neighborhood pharmacy',
        logoUrl: null,
        ownerUserId: currentUserId,
        adminUserIds: ['user_2', 'user_3'],
        address: '123 Main Street, Cairo',
        latitude: 30.0444,
        longitude: 31.2357,
        phone: '+20 2 1234 5678',
        email: 'contact@alshifa.com',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      UserPharmacyModel(
        id: 'pharmacy_2',
        name: 'Sehat Pharmacy',
        description: '24/7 Pharmacy services',
        ownerUserId: 'user_2',
        adminUserIds: [currentUserId],
        address: '456 Tahrir Square, Giza',
        latitude: 30.0131,
        longitude: 31.2089,
        phone: '+20 2 9876 5432',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
}
