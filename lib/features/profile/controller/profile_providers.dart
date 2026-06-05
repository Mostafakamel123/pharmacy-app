import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/auth/service/auth_service.dart';
import 'package:Elaaj/features/profile/model/profile_model.dart';

// USER-SCOPED: Must be invalidated on logout — see auth_invalidation.dart.
// Also auto-resets when the authenticated user changes via ref.watch on isAuthenticated.
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfileModel>>((ref) {
  // Watch isAuthenticated: when it flips true (login) or false (logout/switch),
  // Riverpod disposes this notifier and creates a fresh one automatically.
  // We also watch user?.id so switching accounts (same isAuthenticated=true) also triggers a reset.
  final authKey = ref.watch(
    authProvider.select((s) => '${s.isAuthenticated}_${s.user?.id ?? 'none'}'),
  );
  final isAuthenticated = authKey.startsWith('true');
  return ProfileNotifier(ref, isAuthenticated: isAuthenticated);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfileModel>> {
  final Ref ref;
  final bool isAuthenticated;
  final AuthService _authService = AuthServiceImpl();

  ProfileNotifier(this.ref, {required this.isAuthenticated})
      : super(const AsyncValue.loading()) {
    if (isAuthenticated) {
      _loadProfile();
    } else {
      state = const AsyncValue.loading();
    }
  }

  Future<void> _loadProfile() async {
    try {
      // Get profile from API
      final profileData = await _authService.getProfile();
      
      if (profileData != null) {
        final userProfile = UserProfileModel.fromApi(profileData);
        state = AsyncValue.data(userProfile);
      } else {
        // Fallback to sample data if API fails
        await Future.delayed(const Duration(milliseconds: 400));
        state = AsyncValue.data(UserProfileModel.sample());
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadProfile();
  }

  Future<bool> updateProfile({
    required String name,
    required String dateOfBirth,
    String? imagePath,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final profileData = await _authService.updateUserProfile(
        fullName: name,
        dateOfBirth: dateOfBirth,
        imagePath: imagePath,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      if (profileData != null) {
        // Optimistically update state from the PUT response
        final userProfile = UserProfileModel.fromApi(profileData);
        state = AsyncValue.data(userProfile);
      }
      // Always re-fetch from server to guarantee UI shows latest data
      await _loadProfile();
      return true;
    } catch (e) {
      // Even on failure, try to re-fetch so the UI stays consistent
      try {
        await _loadProfile();
      } catch (_) {}
      return false;
    }
  }

}

// Dark mode provider (synced with platform)
final darkModeProvider = StateProvider<bool>((ref) => false);

// Edit form provider
final editFormProvider =
    StateNotifierProvider<EditFormNotifier, EditFormState>((ref) {
  return EditFormNotifier();
});

class EditFormState {
  final String name;
  final String dateOfBirth;
  final String location;
  final double latitude;
  final double longitude;
  final String? imagePath;
  final bool isSaving;
  final Map<String, String?> errors;

  const EditFormState({
    this.name = '',
    this.dateOfBirth = '',
    this.location = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imagePath,
    this.isSaving = false,
    this.errors = const {},
  });

  bool get isValid =>
      name.trim().isNotEmpty &&
      location.trim().isNotEmpty &&
      dateOfBirth.isNotEmpty;

  EditFormState copyWith({
    String? name,
    String? dateOfBirth,
    String? location,
    double? latitude,
    double? longitude,
    String? imagePath,
    bool? isSaving,
    Map<String, String?>? errors,
  }) {
    return EditFormState(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePath: imagePath ?? this.imagePath,
      isSaving: isSaving ?? this.isSaving,
      errors: errors ?? this.errors,
    );
  }
}

class EditFormNotifier extends StateNotifier<EditFormState> {
  EditFormNotifier() : super(const EditFormState());

  void initialize({
    required String name,
    required String dateOfBirth,
    required String location,
    required double latitude,
    required double longitude,
  }) {
    state = EditFormState(
      name: name,
      dateOfBirth: dateOfBirth,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }

  void updateName(String name) {
    state = state.copyWith(
      name: name,
      errors: {...state.errors, 'name': _validateName(name)},
    );
  }

  void updateDateOfBirth(String dateOfBirth) {
    state = state.copyWith(
      dateOfBirth: dateOfBirth,
      errors: {...state.errors, 'dateOfBirth': _validateDateOfBirth(dateOfBirth)},
    );
  }

  void updateLocation(String location) {
    state = state.copyWith(
      location: location,
      errors: {...state.errors, 'location': _validateLocation(location)},
    );
  }

  void updateCoordinates(double latitude, double longitude) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
  }

  void updateImagePath(String? path) {
    state = state.copyWith(imagePath: path);
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateDateOfBirth(String value) {
    if (value.trim().isEmpty) return 'Date of birth is required';
    return null;
  }

  String? _validateLocation(String value) {
    if (value.trim().isEmpty) return 'Address is required';
    return null;
  }

  Future<bool> save() async {
    if (!state.isValid) return false;

    state = state.copyWith(isSaving: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isSaving: false);
    return true;
  }
}
