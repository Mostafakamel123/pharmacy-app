// ignore_for_file: unused_catch_stack

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/network/api_endpoints.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';
import 'package:pharmacy_app/core/models/pharmacy_model.dart';
import 'package:geolocator/geolocator.dart';

// ============================================================================
// LOCATION PROVIDER - Get user's current location
// ============================================================================

final locationProvider = FutureProvider<LocationData?>((ref) async {
  try {
    // 1. Check if location services are enabled on the device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Services off — fall back to Cairo so nearby pharmacies still load
      return LocationData(latitude: 30.0444, longitude: 31.2357);
    }

    // 2. Check current permission state
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. Request permission if not yet granted
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 4. If user permanently denied — fall back to Cairo
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return LocationData(latitude: 30.0444, longitude: 31.2357);
    }

    // 5. Permission granted — get real position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (e) {
    // Any other failure — fall back to Cairo
    return LocationData(latitude: 30.0444, longitude: 31.2357);
  }
});

class LocationData {
  final double latitude;
  final double longitude;

  LocationData({required this.latitude, required this.longitude});
}

// ============================================================================
// NEARBY PHARMACIES PROVIDER - Connected to /api/Pharmacies/nearby
// ============================================================================

final nearbyPharmaciesProvider = StateNotifierProvider<NearbyPharmaciesNotifier, AsyncValue<List<PharmacyModel>>>((ref) {
  return NearbyPharmaciesNotifier(ref);
});

class NearbyPharmaciesNotifier extends StateNotifier<AsyncValue<List<PharmacyModel>>> {
  final Ref ref;
  final ApiEndpoints _api = ApiEndpoints();

  NearbyPharmaciesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    try {
      state = const AsyncValue.loading();
      
      // Get user location (always returns a value — real GPS or Cairo fallback)
      final locationAsync = await ref.read(locationProvider.future);
      final loc = locationAsync ?? LocationData(latitude: 30.0444, longitude: 31.2357);

      // Call API: GET /api/Pharmacies/nearby
      final response = await _api.getNearbyPharmacies(
        lat: loc.latitude,
        lon: loc.longitude,
        radius: 5.0,
      );

      // Map API response to PharmacyModel
      final pharmacies = (response).map((item) {
        return PharmacyModel.fromJson(item as Map<String, dynamic>);
      }).toList();

      state = AsyncValue.data(pharmacies);
    } catch (e, stack) {
      // On error, return empty list instead of showing error immediately
      state = AsyncValue.data([]);
      print('Error loading nearby pharmacies: $e');
    }
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    await _loadPharmacies();
  }
}

// ============================================================================
// RECENT POSTS PROVIDER - Connected to /api/Posts
// ============================================================================

final recentPostsProvider = StateNotifierProvider<RecentPostsNotifier, AsyncValue<List<PostModel>>>((ref) {
  return RecentPostsNotifier();
});

class RecentPostsNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final ApiEndpoints _api = ApiEndpoints();

  RecentPostsNotifier() : super(const AsyncValue.loading()) {
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      state = const AsyncValue.loading();
      print('🟡 RecentPostsNotifier: Starting to load posts...');

      // Call API: GET /api/Posts?pageNumber=1&pageSize=5
      final response = await _api.getPosts(pageNumber: 1, pageSize: 5);
      print('🟡 RecentPostsNotifier: API response received: ${response.length} items');

      // Map API response to PostModel
      final posts = (response).map((item) {
        return PostModel.fromJson(item as Map<String, dynamic>);
      }).toList();

      // If API returns data, use it
      if (posts.isNotEmpty) {
        print('🟢 RecentPostsNotifier: API returned ${posts.length} posts');
        state = AsyncValue.data(posts);
      } else {
        print('⚠️  RecentPostsNotifier: API returned empty list');
        state = AsyncValue.data([]);
      }
    } catch (e, stack) {
      // On error, show error state
      print('🔴 RecentPostsNotifier: Error loading posts: $e');
      print('🔴 Stack trace: $stack');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    await _loadPosts();
  }
}

// ============================================================================
// SEARCH QUERY PROVIDER
// ============================================================================

final searchQueryProvider = StateProvider<String>((ref) => '');

// ============================================================================
// PHARMACY SEARCH PROVIDER  - GET /api/Pharmacies/search
// When query is empty  → re-exposes nearbyPharmaciesProvider (no extra call).
// When query is set    → calls the search endpoint and returns live results.
// ============================================================================

final pharmacySearchProvider =
    StateNotifierProvider<PharmacySearchNotifier, AsyncValue<List<PharmacyModel>>>(
  (ref) => PharmacySearchNotifier(ref),
);

class PharmacySearchNotifier
    extends StateNotifier<AsyncValue<List<PharmacyModel>>> {
  final Ref _ref;
  final ApiEndpoints _api = ApiEndpoints();

  PharmacySearchNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Start with the nearby list.
    _syncWithNearby();
    // Re-run search whenever the query changes.
    _ref.listen<String>(searchQueryProvider, (_, query) {
      if (query.isEmpty) {
        _syncWithNearby();
      } else {
        search(query);
      }
    });
  }

  /// Mirror the current nearbyPharmaciesProvider state directly.
  void _syncWithNearby() {
    state = _ref.read(nearbyPharmaciesProvider);
  }

  /// Call GET /api/Pharmacies/search?keyword=...
  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      _syncWithNearby();
      return;
    }
    try {
      state = const AsyncValue.loading();
      final raw = await _api.searchPharmacies(
        keyword: keyword.trim(),
        pageSize: 20,
      );
      final results = raw
          .map((item) => PharmacyModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ============================================================================
// FILTERED NEARBY PHARMACIES PROVIDER
// Kept for backward-compatibility — delegates to pharmacySearchProvider.
// ============================================================================

final filteredNearbyPharmaciesProvider =
    Provider<AsyncValue<List<PharmacyModel>>>(
  (ref) => ref.watch(pharmacySearchProvider),
);

// ============================================================================
// NOTIFICATION COUNT PROVIDER
// ============================================================================

final notificationCountProvider = StateProvider<int>((ref) => 0);
