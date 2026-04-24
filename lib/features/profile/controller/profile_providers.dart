import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/profile/model/profile_model.dart';

// Profile provider
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfileModel>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfileModel>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      state = AsyncValue.data(UserProfileModel.sample());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadProfile();
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? location,
  }) async {
    final current = state.asData?.value;
    if (current == null) return false;

    state = AsyncValue.data(UserProfileModel(
      id: current.id,
      name: name ?? current.name,
      email: current.email,
      phone: phone ?? current.phone,
      location: location ?? current.location,
      avatarUrl: current.avatarUrl,
      postsCount: current.postsCount,
      repliesCount: current.repliesCount,
      savedCount: current.savedCount,
      completionPercentage: _calculateCompletion(
        name ?? current.name,
        current.email,
        phone ?? current.phone,
        location ?? current.location,
      ),
      joinDate: current.joinDate,
    ));
    return true;
  }

  double _calculateCompletion(
      String name, String email, String phone, String? location) {
    double score = 0;
    if (name.isNotEmpty) score += 0.3;
    if (email.isNotEmpty) score += 0.3;
    if (phone.isNotEmpty) score += 0.2;
    if (location != null && location.isNotEmpty) score += 0.2;
    return score;
  }

  Future<void> uploadAvatar() async {
    // Simulate avatar upload
    await Future.delayed(const Duration(milliseconds: 800));
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
  final String phone;
  final String? location;
  final bool isSaving;
  final Map<String, String?> errors;

  const EditFormState({
    this.name = '',
    this.phone = '',
    this.location,
    this.isSaving = false,
    this.errors = const {},
  });

  bool get isValid => name.trim().isNotEmpty && phone.trim().isNotEmpty;

  EditFormState copyWith({
    String? name,
    String? phone,
    String? location,
    bool? isSaving,
    Map<String, String?>? errors,
  }) {
    return EditFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      isSaving: isSaving ?? this.isSaving,
      errors: errors ?? this.errors,
    );
  }
}

class EditFormNotifier extends StateNotifier<EditFormState> {
  EditFormNotifier() : super(const EditFormState());

  void initialize(String name, String phone, String? location) {
    state = EditFormState(
      name: name,
      phone: phone,
      location: location,
    );
  }

  void updateName(String name) {
    state = state.copyWith(
      name: name,
      errors: {...state.errors, 'name': _validateName(name)},
    );
  }

  void updatePhone(String phone) {
    state = state.copyWith(
      phone: phone,
      errors: {...state.errors, 'phone': _validatePhone(phone)},
    );
  }

  void updateLocation(String? location) {
    state = state.copyWith(location: location);
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) return 'Phone is required';
    return null;
  }

  Future<bool> save() async {
    if (!state.isValid) return false;

    state = state.copyWith(isSaving: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = state.copyWith(isSaving: false);
    return true;
  }
}
