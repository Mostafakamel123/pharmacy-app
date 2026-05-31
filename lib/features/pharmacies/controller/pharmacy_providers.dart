import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/network/api_endpoints.dart';
import 'package:pharmacy_app/core/models/pharmacy_model.dart';

// Nearby pharmacies provider
final nearbyPharmaciesProvider = StateNotifierProvider<NearbyPharmaciesNotifier, AsyncValue<List<PharmacyModel>>>((ref) {
  return NearbyPharmaciesNotifier();
});

class NearbyPharmaciesNotifier extends StateNotifier<AsyncValue<List<PharmacyModel>>> {
  late final ApiEndpoints _apiEndpoints;
  
  NearbyPharmaciesNotifier() : super(const AsyncValue.loading()) {
    _apiEndpoints = ApiEndpoints();
    _loadPharmacies();
  }

  bool _openNow = false;
  bool _hasDelivery = false;
  double _maxDistance = 5.0;
  String _searchQuery = '';
  double _latitude = 30.0444; // Default Cairo latitude
  double _longitude = 31.2357; // Default Cairo longitude

  Future<void> _loadPharmacies() async {
    try {
      // Call API to get nearby pharmacies
      final response = await _apiEndpoints.getNearbyPharmacies(
        lat: _latitude,
        lon: _longitude,
        radius: _maxDistance,
      );
      
      // Convert to PharmacyModel list
      var pharmacies = response
          .map((json) => _parsePharmacyFromJson(json as Map<String, dynamic>))
          .toList();

      // Apply filters
      if (_openNow) {
        pharmacies = pharmacies.where((p) => p.isOpen).toList();
      }
      if (_hasDelivery) {
        pharmacies = pharmacies.where((p) => p.hasDelivery).toList();
      }
      pharmacies = pharmacies.where((p) => p.distance <= _maxDistance).toList();

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        pharmacies = pharmacies
            .where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.address.toLowerCase().contains(query))
            .toList();
      }

      // Sort by distance
      pharmacies.sort((a, b) => a.distance.compareTo(b.distance));

      state = AsyncValue.data(pharmacies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Parse pharmacy from JSON response
  PharmacyModel _parsePharmacyFromJson(Map<String, dynamic> json) {
    // Check if distance is already returned by API, otherwise calculate it manually from coordinates (in km)
    final distance = (json['distance'] as num?)?.toDouble() ?? _calculateDistance(
      _latitude,
      _longitude,
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
    
    return PharmacyModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      address: json['address'] as String? ?? '',
      distance: distance,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isOpen: json['isOpen'] as bool? ?? true,
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['contactNumber'] as String?,
      openingHours: json['workingHours'] as String?,
      closingHours: null,
      isVerified: json['isVerified'] as bool? ?? true,
      estimatedDeliveryMinutes: json['estimatedDeliveryMinutes'] as int?,
    );
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPharmacies();
  }

  void toggleOpenNow(bool value) {
    _openNow = value;
    _loadPharmacies();
  }

  void toggleDelivery(bool value) {
    _hasDelivery = value;
    _loadPharmacies();
  }

  void setMaxDistance(double value) {
    _maxDistance = value;
    _loadPharmacies();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    _loadPharmacies();
  }

  /// Set current location for nearby search
  void setLocation(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
    _loadPharmacies();
  }
}

// Selected pharmacy provider
final selectedPharmacyProvider = StateProvider<PharmacyModel?>((ref) => null);

// Favorites provider
final favoritePharmaciesProvider = StateNotifierProvider<FavoritePharmaciesNotifier, Set<String>>((ref) {
  return FavoritePharmaciesNotifier();
});

class FavoritePharmaciesNotifier extends StateNotifier<Set<String>> {
  late final ApiEndpoints _apiEndpoints;
  
  FavoritePharmaciesNotifier() : super({}) {
    _apiEndpoints = ApiEndpoints();
  }

  /// Toggle favorite status for a pharmacy
  Future<void> toggleFavorite(String pharmacyId) async {
    try {
      // Call API to toggle favorite
      await _apiEndpoints.toggleFavorite(pharmacyId: pharmacyId);
      
      // Update local state
      final updated = Set<String>.from(state);
      if (updated.contains(pharmacyId)) {
        updated.remove(pharmacyId);
      } else {
        updated.add(pharmacyId);
      }
      state = updated;
    } catch (e) {
      // If API fails, still update local state for better UX
      final updated = Set<String>.from(state);
      if (updated.contains(pharmacyId)) {
        updated.remove(pharmacyId);
      } else {
        updated.add(pharmacyId);
      }
      state = updated;
    }
  }

  /// Check if a pharmacy is favorite
  bool isFavorite(String pharmacyId) {
    return state.contains(pharmacyId);
  }
}
