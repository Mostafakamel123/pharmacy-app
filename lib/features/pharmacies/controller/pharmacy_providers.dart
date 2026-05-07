import 'dart:async'; // PERF FIX: Add Timer for debounce
import 'package:flutter/foundation.dart'; // PERF FIX: Add compute for heavy operations
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
  Timer? _debounceTimer; // PERF FIX: Add debounce timer

  @override
  void dispose() {
    _debounceTimer?.cancel(); // PERF FIX: Cancel timer on dispose
    super.dispose();
  }

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

      // PERF FIX: Move sorting to compute() for large lists (>20 items)
      if (pharmacies.length > 20) {
        pharmacies = await compute(_sortPharmaciesByDistance, pharmacies);
      } else {
        // Sort by distance
        pharmacies.sort((a, b) => a.distance.compareTo(b.distance));
      }

      state = AsyncValue.data(pharmacies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // PERF FIX: Static helper for compute()
  static List<PharmacyModel> _sortPharmaciesByDistance(List<PharmacyModel> pharmacies) {
    pharmacies.sort((a, b) => a.distance.compareTo(b.distance));
    return pharmacies;
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

  // PERF FIX: Debounce search query to avoid excessive filtering
  void setSearchQuery(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = value;
      _loadPharmacies();
    });
  }
}

// Selected pharmacy provider
final selectedPharmacyProvider = StateProvider<PharmacyModel?>((ref) => null);

// Favorites provider
final favoritePharmaciesProvider = StateProvider<Set<String>>((ref) => {});
