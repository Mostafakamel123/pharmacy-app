class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final double distance;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final bool hasDelivery;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? openingHours;
  final String? closingHours;
  final bool isVerified;
  final int? estimatedDeliveryMinutes;
  final bool isFavorite;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    this.hasDelivery = false,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.openingHours,
    this.closingHours,
    this.isVerified = true,
    this.estimatedDeliveryMinutes,
    this.isFavorite = false,
  });

  // Factory constructor to create from JSON (API response)
  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Pharmacy',
      address: json['address'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isOpen: json['isOpen'] as bool? ?? true,
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] as String?,
      openingHours: json['openingHours'] as String?,
      closingHours: json['closingHours'] as String?,
      isVerified: json['isVerified'] as bool? ?? true,
      estimatedDeliveryMinutes: json['estimatedDeliveryMinutes'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'distance': distance,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOpen': isOpen,
      'hasDelivery': hasDelivery,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'openingHours': openingHours,
      'closingHours': closingHours,
      'isVerified': isVerified,
      'estimatedDeliveryMinutes': estimatedDeliveryMinutes,
      'isFavorite': isFavorite,
    };
  }

  String get statusText => isOpen ? 'Open' : 'Closed';

  String get workingHours {
    if (openingHours == null || closingHours == null) return 'Not available';
    return '$openingHours - $closingHours';
  }

  // Sample data for testing
  static List<PharmacyModel> sample() {
    return [
      const PharmacyModel(
        id: '1',
        name: 'صيدلية ابوكمال ',
        address: 'المعلمين ,اسيوط',
        distance: 0.8,
        rating: 4.8,
        reviewCount: 234,
        isOpen: true,
        hasDelivery: true,
        latitude: 30.0626,
        longitude: 31.2003,
        phone: '+200000000000',
        openingHours: '09:00 AM',
        closingHours: '02:00 AM',
        estimatedDeliveryMinutes: 25,
      ),
      const PharmacyModel(
        id: '2',
        name: 'صيدلية الدولييي',
        address: 'المعتلمين برضو ',
        distance: 1.2,
        rating: 4.5,
        reviewCount: 189,
        isOpen: true,
        hasDelivery: false,
        latitude: 30.0444,
        longitude: 31.2127,
        phone: '+200000000000',
        openingHours: '08:00 AM',
        closingHours: '12:00 AM',
      ),
      const PharmacyModel(
        id: '3',
        name: 'الغنايم وال منها ',
        address: 'الغنايم ,اسيوط',
        distance: 1.5,
        rating: 4.9,
        reviewCount: 412,
        isOpen: false,
        hasDelivery: true,
        latitude: 30.0618,
        longitude: 31.2015,
        phone: '+200000000000',
        openingHours: '10:00 AM',
        closingHours: '01:00 AM',
        estimatedDeliveryMinutes: 35,
      ),
      const PharmacyModel(
        id: '4',
        name: 'صيدلية اولاد كامل ',
        address: 'مسارة ,اسيوط',
        distance: 2.1,
        rating: 4.3,
        reviewCount: 156,
        isOpen: true,
        hasDelivery: true,
        latitude: 30.0650,
        longitude: 31.2025,
        phone: '+200000000000',
        openingHours: '24 Hours',
        closingHours: '24 Hours',
        estimatedDeliveryMinutes: 20,
      ),
      const PharmacyModel(
        id: '5',
        name: 'صيدلية اولاد الحاج عمر',
        address: 'ريفق ,اسيوط',
        distance: 2.8,
        rating: 4.6,
        reviewCount: 203,
        isOpen: true,
        hasDelivery: false,
        latitude: 30.0410,
        longitude: 31.2100,
        phone: '+200000000000',
        openingHours: '07:00 AM',
        closingHours: '11:00 PM',
      ),
    ];
  }
}
