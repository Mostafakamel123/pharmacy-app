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
        name: 'El-Ezaby Pharmacy',
        address: '14 Hassan El-Mamoun, Mohandessin',
        distance: 0.8,
        rating: 4.8,
        reviewCount: 234,
        isOpen: true,
        hasDelivery: true,
        latitude: 30.0626,
        longitude: 31.2003,
        phone: '+20 2 33456789',
        openingHours: '09:00 AM',
        closingHours: '02:00 AM',
        estimatedDeliveryMinutes: 25,
      ),
      const PharmacyModel(
        id: '2',
        name: 'Seif Pharmacy',
        address: '26 Gameat El-Dowal, Dokki',
        distance: 1.2,
        rating: 4.5,
        reviewCount: 189,
        isOpen: true,
        hasDelivery: false,
        latitude: 30.0444,
        longitude: 31.2127,
        phone: '+20 2 37654321',
        openingHours: '08:00 AM',
        closingHours: '12:00 AM',
      ),
      const PharmacyModel(
        id: '3',
        name: 'Dr. Ragab Pharmacy',
        address: '8 Ahmed Orabi, Mohandessin',
        distance: 1.5,
        rating: 4.9,
        reviewCount: 412,
        isOpen: false,
        hasDelivery: true,
        latitude: 30.0618,
        longitude: 31.2015,
        phone: '+20 2 33987654',
        openingHours: '10:00 AM',
        closingHours: '01:00 AM',
        estimatedDeliveryMinutes: 35,
      ),
      const PharmacyModel(
        id: '4',
        name: 'Al-Nour Pharmacy',
        address: '32 Syria, Mohandessin',
        distance: 2.1,
        rating: 4.3,
        reviewCount: 156,
        isOpen: true,
        hasDelivery: true,
        latitude: 30.0650,
        longitude: 31.2025,
        phone: '+20 2 33112233',
        openingHours: '24 Hours',
        closingHours: '24 Hours',
        estimatedDeliveryMinutes: 20,
      ),
      const PharmacyModel(
        id: '5',
        name: 'Care Pharmacy',
        address: '5 Lebanon, Dokki',
        distance: 2.8,
        rating: 4.6,
        reviewCount: 203,
        isOpen: true,
        hasDelivery: false,
        latitude: 30.0410,
        longitude: 31.2100,
        phone: '+20 2 33445566',
        openingHours: '07:00 AM',
        closingHours: '11:00 PM',
      ),
    ];
  }
}
