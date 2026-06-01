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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (e) {
    // Return default location (Cairo) if geolocation fails
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
      
      // Get user location
      final locationAsync = await ref.read(locationProvider.future);
      if (locationAsync == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Call API: GET /api/Pharmacies/nearby
      final response = await _api.getNearbyPharmacies(
        lat: locationAsync.latitude,
        lon: locationAsync.longitude,
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
// FILTERED NEARBY PHARMACIES PROVIDER - Combines nearbyPharmaciesProvider & searchQueryProvider
// ============================================================================

final filteredNearbyPharmaciesProvider = Provider<AsyncValue<List<PharmacyModel>>>((ref) {
  final pharmaciesAsync = ref.watch(nearbyPharmaciesProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return pharmaciesAsync;
  }

  return pharmaciesAsync.whenData((list) {
    return list.where((pharmacy) {
      return pharmacy.name.toLowerCase().contains(searchQuery) ||
             pharmacy.address.toLowerCase().contains(searchQuery);
    }).toList();
  });
});

// ============================================================================
// SEARCH QUERY PROVIDER
// ============================================================================

final searchQueryProvider = StateProvider<String>((ref) => '');

// ============================================================================
// NOTIFICATION COUNT PROVIDER - Placeholder for future implementation
// ============================================================================

final notificationCountProvider = StateProvider<int>((ref) => 0);
