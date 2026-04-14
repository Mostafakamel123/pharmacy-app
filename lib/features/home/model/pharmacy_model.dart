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
  });

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
      ),
    ];
  }
}
