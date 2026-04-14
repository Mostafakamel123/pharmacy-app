import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/home/model/pharmacy_model.dart';

// Nearby pharmacies provider
final nearbyPharmaciesProvider = StateNotifierProvider<NearbyPharmaciesNotifier, AsyncValue<List<PharmacyModel>>>((ref) {
  return NearbyPharmaciesNotifier();
});

class NearbyPharmaciesNotifier extends StateNotifier<AsyncValue<List<PharmacyModel>>> {
  NearbyPharmaciesNotifier() : super(const AsyncValue.loading()) {
    _loadPharmacies();
  }

  bool _openNow = false;
  bool _hasDelivery = false;
  double _maxDistance = 5.0;
  String _searchQuery = '';

  Future<void> _loadPharmacies() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      var pharmacies = PharmacyModel.sample();

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
}

// Selected pharmacy provider
final selectedPharmacyProvider = StateProvider<PharmacyModel?>((ref) => null);

// Favorites provider
final favoritePharmaciesProvider = StateProvider<Set<String>>((ref) => {});
