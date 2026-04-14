import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/home/model/home_post_model.dart';
import 'package:pharmacy_app/features/home/model/pharmacy_model.dart';

// Simulated loading delay
const _loadingDelay = Duration(milliseconds: 800);

// Nearby pharmacies provider
final nearbyPharmaciesProvider = StateNotifierProvider<NearbyPharmaciesNotifier, AsyncValue<List<PharmacyModel>>>((ref) {
  return NearbyPharmaciesNotifier();
});

class NearbyPharmaciesNotifier extends StateNotifier<AsyncValue<List<PharmacyModel>>> {
  NearbyPharmaciesNotifier() : super(const AsyncValue.loading()) {
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    try {
      await Future.delayed(_loadingDelay);
      state = AsyncValue.data(PharmacyModel.sample());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPharmacies();
  }
}

// Recent posts provider
final recentPostsProvider = StateNotifierProvider<RecentPostsNotifier, AsyncValue<List<HomePostModel>>>((ref) {
  return RecentPostsNotifier();
});

class RecentPostsNotifier extends StateNotifier<AsyncValue<List<HomePostModel>>> {
  RecentPostsNotifier() : super(const AsyncValue.loading()) {
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      await Future.delayed(_loadingDelay);
      state = AsyncValue.data(HomePostModel.sample());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPosts();
  }
}

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Notification count provider
final notificationCountProvider = StateProvider<int>((ref) => 3);
