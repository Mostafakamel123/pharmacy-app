import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';

/// Provider for managing user's pharmacies
final myPharmaciesProvider = StateNotifierProvider<MyPharmaciesNotifier, AsyncValue<List<UserPharmacyModel>>>((ref) {
  return MyPharmaciesNotifier(ref);
});

class MyPharmaciesNotifier extends StateNotifier<AsyncValue<List<UserPharmacyModel>>> {
  final Ref ref;

  MyPharmaciesNotifier(this.ref) : super(const AsyncValue.loading());

  /// Load user's pharmacies from API
  Future<void> loadUserPharmacies() async {
    state = const AsyncValue.loading();
    
    try {
      // TODO: Replace with actual API call
      // Example: final response = await apiService.getMyPharmacies();
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Get current user ID (replace with actual auth provider)
      final currentUserId = ref.read(currentUserIdProvider);
      
      // Load sample data
      final pharmacies = UserPharmacyModel.sampleData(currentUserId);
      
      // Update pharmacy mode state with loaded pharmacies
      ref.read(pharmacyModeProvider.notifier).setUserPharmacies(pharmacies);
      
      state = AsyncValue.data(pharmacies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new pharmacy
  Future<UserPharmacyModel?> createPharmacy(UserPharmacyModel pharmacy) async {
    try {
      state = const AsyncValue.loading();
      
      // TODO: Replace with actual API call
      // Example: final response = await apiService.createPharmacy(pharmacy.toJson());
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Add to local list
      final currentState = state.value ?? [];
      final updatedList = [...currentState, pharmacy];
      
      // Update pharmacy mode state
      ref.read(pharmacyModeProvider.notifier).addPharmacy(pharmacy);
      
      state = AsyncValue.data(updatedList);
      
      return pharmacy;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Update an existing pharmacy
  Future<bool> updatePharmacy(UserPharmacyModel updatedPharmacy) async {
    try {
      // TODO: Replace with actual API call
      // Example: final response = await apiService.updatePharmacy(updatedPharmacy.id, updatedPharmacy.toJson());
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Update in local list
      final currentState = state.value ?? [];
      final updatedList = currentState.map((p) {
        if (p.id == updatedPharmacy.id) {
          return updatedPharmacy;
        }
        return p;
      }).toList();
      
      // Update pharmacy mode state
      ref.read(pharmacyModeProvider.notifier).updatePharmacy(updatedPharmacy);
      
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
      // TODO: Replace with actual API call
      // Example: await apiService.deletePharmacy(pharmacyId);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
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

/// Temporary provider for current user ID
/// TODO: Replace with actual auth provider
final currentUserIdProvider = Provider<String>((ref) {
  return 'current_user_id';
});
