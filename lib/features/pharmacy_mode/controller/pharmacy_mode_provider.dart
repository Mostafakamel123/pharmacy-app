import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_pharmacy_model.dart';

/// Application mode enum
enum AppMode {
  /// User is browsing in personal mode
  personal,

  /// User is managing a pharmacy
  pharmacy,
}

/// Pharmacy mode state
class PharmacyModeState {
  final AppMode currentMode;
  final UserPharmacyModel? currentPharmacy;
  final List<UserPharmacyModel> userPharmacies;
  final bool isLoading;
  final String? error;

  const PharmacyModeState({
    this.currentMode = AppMode.personal,
    this.currentPharmacy,
    this.userPharmacies = const [],
    this.isLoading = false,
    this.error,
  });

  /// Check if currently in pharmacy mode
  bool get isPharmacyMode => currentMode == AppMode.pharmacy;

  /// Check if currently in personal mode
  bool get isPersonalMode => currentMode == AppMode.personal;

  /// Get the current context ID (pharmacy ID or null for personal)
  String? get currentContextId => currentPharmacy?.id;

  /// Copy with updated fields
  PharmacyModeState copyWith({
    AppMode? currentMode,
    UserPharmacyModel? currentPharmacy,
    List<UserPharmacyModel>? userPharmacies,
    bool? isLoading,
    String? error,
  }) {
    return PharmacyModeState(
      currentMode: currentMode ?? this.currentMode,
      currentPharmacy: currentPharmacy ?? this.currentPharmacy,
      userPharmacies: userPharmacies ?? this.userPharmacies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for pharmacy mode management
class PharmacyModeNotifier extends StateNotifier<PharmacyModeState> {
  PharmacyModeNotifier() : super(const PharmacyModeState());

  /// Switch to personal mode
  void switchToPersonalMode() {
    state = state.copyWith(
      currentMode: AppMode.personal,
      currentPharmacy: null,
    );
  }

  /// Switch to pharmacy mode with a specific pharmacy
  void switchToPharmacyMode(UserPharmacyModel pharmacy) {
    state = state.copyWith(
      currentMode: AppMode.pharmacy,
      currentPharmacy: pharmacy,
    );
  }

  /// Toggle between personal and pharmacy mode
  void toggleMode() {
    if (state.isPersonalMode && state.userPharmacies.isNotEmpty) {
      // Switch to first pharmacy if available
      switchToPharmacyMode(state.userPharmacies.first);
    } else {
      switchToPersonalMode();
    }
  }

  /// Set the list of pharmacies the user owns/manages
  void setUserPharmacies(List<UserPharmacyModel> pharmacies) {
    state = state.copyWith(
      userPharmacies: pharmacies,
      isLoading: false,
    );
  }

  /// Add a new pharmacy to the list
  void addPharmacy(UserPharmacyModel pharmacy) {
    state = state.copyWith(
      userPharmacies: [...state.userPharmacies, pharmacy],
    );

    // If in personal mode, switch to the new pharmacy
    if (state.isPersonalMode) {
      switchToPharmacyMode(pharmacy);
    }
  }

  /// Remove a pharmacy from the list
  void removePharmacy(String pharmacyId) {
    final updatedList = state.userPharmacies
        .where((p) => p.id != pharmacyId)
        .toList();

    state = state.copyWith(
      userPharmacies: updatedList,
    );

    // If removing current pharmacy, switch to personal mode
    if (state.currentPharmacy?.id == pharmacyId) {
      switchToPersonalMode();
    }
  }

  /// Update a pharmacy in the list
  void updatePharmacy(UserPharmacyModel updatedPharmacy) {
    final updatedList = state.userPharmacies.map((p) {
      if (p.id == updatedPharmacy.id) {
        return updatedPharmacy;
      }
      return p;
    }).toList();

    state = state.copyWith(
      userPharmacies: updatedList,
      // Update current pharmacy if it's the one being updated
      currentPharmacy: state.currentPharmacy?.id == updatedPharmacy.id
          ? updatedPharmacy
          : state.currentPharmacy,
    );
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error state
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Load user's pharmacies (simulate API call)
  Future<void> loadUserPharmacies(String userId) async {
    setLoading(true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      final samplePharmacies = UserPharmacyModel.sampleData(userId);
      setUserPharmacies(samplePharmacies);
    } catch (e) {
      setError('Failed to load pharmacies: $e');
      setLoading(false);
    }
  }
}

/// Provider for pharmacy mode state
final pharmacyModeProvider = StateNotifierProvider<PharmacyModeNotifier, PharmacyModeState>(
  (ref) => PharmacyModeNotifier(),
);

/// Selector for current mode
final currentAppModeProvider = Provider<AppMode>((ref) {
  return ref.watch(pharmacyModeProvider).currentMode;
});

/// Selector for current pharmacy (null if in personal mode)
final currentPharmacyProvider = Provider<UserPharmacyModel?>((ref) {
  return ref.watch(pharmacyModeProvider).currentPharmacy;
});

/// Selector for user's pharmacies list
final userPharmaciesProvider = Provider<List<UserPharmacyModel>>((ref) {
  return ref.watch(pharmacyModeProvider).userPharmacies;
});

/// Selector for checking if in pharmacy mode
final isPharmacyModeProvider = Provider<bool>((ref) {
  return ref.watch(pharmacyModeProvider).isPharmacyMode;
});
