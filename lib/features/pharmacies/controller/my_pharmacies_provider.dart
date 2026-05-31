import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/network/api_endpoints.dart';
import 'package:pharmacy_app/features/auth/controller/auth_providers.dart';
import 'package:pharmacy_app/features/auth/service/auth_service.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';

/// Provider for managing user's pharmacies
final myPharmaciesProvider = StateNotifierProvider<MyPharmaciesNotifier, AsyncValue<List<UserPharmacyModel>>>((ref) {
  return MyPharmaciesNotifier(ref);
});

class MyPharmaciesNotifier extends StateNotifier<AsyncValue<List<UserPharmacyModel>>> {
  final Ref ref;
  late final ApiEndpoints _apiEndpoints;

  MyPharmaciesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _apiEndpoints = ApiEndpoints();
  }

  /// Load user's pharmacies from API
  Future<void> loadUserPharmacies() async {
    state = const AsyncValue.loading();
    
    try {
      // Get current user's pharmacies list
      final response = await _apiEndpoints.getMyPharmacies();
      
      // Fetch full detailed pharmacy information for each in parallel
      final detailedPharmacies = await Future.wait(
        response.map((item) async {
          final id = item['id'] as String;
          try {
            final fullDetails = await _apiEndpoints.getPharmacyById(id: id);
            return UserPharmacyModel.fromJson(fullDetails);
          } catch (e) {
            // Fallback to basic info if full details fetch fails
            final mapItem = item as Map<String, dynamic>;
            return UserPharmacyModel.fromJson({
              ...mapItem,
              'ownerId': mapItem['role'] == 'Owner' ? ref.read(currentUserIdProvider) : '',
            });
          }
        }),
      );
      
      // Update pharmacy mode state with loaded pharmacies
      ref.read(pharmacyModeProvider.notifier).setUserPharmacies(detailedPharmacies);
      
      state = AsyncValue.data(detailedPharmacies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new pharmacy
  Future<UserPharmacyModel?> createPharmacy(UserPharmacyModel pharmacy) async {
    try {
      state = const AsyncValue.loading();
      
      // Call API to create pharmacy
      final response = await _apiEndpoints.createPharmacy(
        name: pharmacy.name,
        imagePath: pharmacy.logoUrl,
        address: pharmacy.address,
        latitude: pharmacy.latitude,
        longitude: pharmacy.longitude,
        contactNumber: pharmacy.phone,
        workingHours: pharmacy.workingHours,
        hasDelivery: pharmacy.hasDelivery,
      );
      
      // Parse the created pharmacy from response
      final createdPharmacy = UserPharmacyModel.fromJson(response);
      
      // Add to local list
      final currentState = state.value ?? [];
      final updatedList = [...currentState, createdPharmacy];
      
      // Update pharmacy mode state
      ref.read(pharmacyModeProvider.notifier).addPharmacy(createdPharmacy);
      
      state = AsyncValue.data(updatedList);
      
      return createdPharmacy;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Update an existing pharmacy
  Future<bool> updatePharmacy(UserPharmacyModel updatedPharmacy, {String? imagePath}) async {
    try {
      // Call API to update pharmacy
      await _apiEndpoints.updatePharmacy(
        id: updatedPharmacy.id,
        name: updatedPharmacy.name,
        imagePath: imagePath ?? updatedPharmacy.logoUrl,
        address: updatedPharmacy.address,
        latitude: updatedPharmacy.latitude,
        longitude: updatedPharmacy.longitude,
        contactNumber: updatedPharmacy.phone,
        workingHours: updatedPharmacy.workingHours,
        hasDelivery: updatedPharmacy.hasDelivery,
      );
      
      // Since the API returns success: true rather than the pharmacy model,
      // we use updatedPharmacy directly as the parsed pharmacy.
      final pharmacy = updatedPharmacy;
      
      // Update in local list
      final currentState = state.value ?? [];
      final updatedList = currentState.map((p) {
        if (p.id == pharmacy.id) {
          return pharmacy;
        }
        return p;
      }).toList();
      
      // Update pharmacy mode state
      ref.read(pharmacyModeProvider.notifier).updatePharmacy(pharmacy);
      
      state = AsyncValue.data(updatedList);
      
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Delete a pharmacy
  Future<bool> deletePharmacy(String pharmacyId) async {
    try {
      // Call API to delete pharmacy
      await _apiEndpoints.deletePharmacy(id: pharmacyId);
      
      // Remove from local list
      final currentState = state.value ?? [];
      final updatedList = currentState.where((p) => p.id != pharmacyId).toList();
      
      // Update pharmacy mode state
      ref.read(pharmacyModeProvider.notifier).removePharmacy(pharmacyId);
      
      state = AsyncValue.data(updatedList);
      
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Remove admin from pharmacy
  Future<bool> removeAdmin(String pharmacyId, String userId) async {
    try {
      // TODO: Replace with actual API call when endpoint is available
      // Example: await _apiEndpoints.addAdmin(pharmacyId, userId);
      // Call API to remove admin - using AuthService for role management
      final authService = AuthServiceImpl();
      
      // Remove the PharmacyAdmin role from the user for this pharmacy
      // Note: This assumes the backend handles pharmacy-specific admin removal
      await authService.removeUserRole(
        userEmail: userId, // This might need to be adjusted based on actual API
        roleName: 'PharmacyAdmin',
      );
      
      // Update in local list
      final currentState = state.value ?? [];
      final updatedList = currentState.map((p) {
        if (p.id == pharmacyId) {
          final updatedAdminIds = p.adminUserIds.where((id) => id != userId).toList();
          return p.copyWith(adminUserIds: updatedAdminIds);
        }
        return p;
      }).toList();
      
      state = AsyncValue.data(updatedList);
      
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Add admin to pharmacy
  Future<bool> addAdmin(String pharmacyId, String userId) async {
    try {
      // TODO: Replace with actual API call when endpoint is available
      // Example: await _apiEndpoints.removeAdmin(pharmacyId, userId);
      // Call API to assign pharmacy admin
      final authService = AuthServiceImpl();
      
      // Assign PharmacyAdmin role to the user
      await authService.assignPharmacyAdmin(
        userId: userId,
        pharmacyId: pharmacyId,
      );
      
      // Update in local list
      final currentState = state.value ?? [];
      final updatedList = currentState.map((p) {
        if (p.id == pharmacyId) {
          final updatedAdminIds = List<String>.from(p.adminUserIds)..add(userId);
          return p.copyWith(adminUserIds: updatedAdminIds);
        }
        return p;
      }).toList();
      
      state = AsyncValue.data(updatedList);
      
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// Real provider for current user ID linked to auth state
final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user?.id ?? '';
});
