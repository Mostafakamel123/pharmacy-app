import 'package:Elaaj/core/constants/app_constants.dart';
import 'package:Elaaj/core/helpers/local_storage_helper.dart';
import 'package:Elaaj/features/auth/model/auth_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/features/auth/service/auth_service.dart';


/// Authentication state
class AuthState {
  final AuthUser? user;
  final bool isAuthenticated;
  final bool isEmailVerified;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isEmailVerified = false,
  });

  AuthState copyWith({
    AuthUser? user,
    bool? isAuthenticated,
    bool? isEmailVerified,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  /// Initial state
  static const initial = AuthState();
}

/// Auth notifier using StateNotifier (following existing pattern)
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(_getInitialState()) {
    // Check if user is already logged in on initialization
    _checkAuthStatus();
  }

  /// Get initial state synchronously from local storage
  static AuthState _getInitialState() {
    try {
      final token = LocalStorageHelper.getStringSync(AppConstants.authTokenKey);
      if (token != null && token.isNotEmpty) {
        final userData = LocalStorageHelper.getObjectSync<AuthUser>(
          AppConstants.userDataKey,
          fromJson: (json) => AuthUser.fromJson(json as Map<String, dynamic>),
        );
        if (userData != null) {
          return AuthState(
            user: userData,
            isAuthenticated: true,
            isEmailVerified: userData.emailVerified,
          );
        }
      }
    } catch (e) {
      // Ignore reading errors at startup
    }
    return AuthState.initial;
  }

  /// Check authentication status from local storage
  Future<void> _checkAuthStatus() async {
    try {
      final token = LocalStorageHelper.getStringSync(AppConstants.authTokenKey);
      if (token == null || token.isEmpty) {
        state = AuthState.initial;
        return;
      }

      // Get FULL profile from /api/identity/profile (includes id, fullName, etc.)
      // This is more reliable than /api/identity/manage/info which only returns email.
      final profileData = await _authService.getProfile();

      if (profileData != null && profileData.isNotEmpty) {
        final user = AuthUser.fromJson(profileData);
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isEmailVerified: user.emailVerified,
        );
        // Cache the fresh profile info
        await LocalStorageHelper.setObject(AppConstants.userDataKey, profileData);
      } else {
        // Profile API failed — fallback to manage/info for at least email verification status
        final infoData = await _authService.getProfileInfo();
        if (infoData != null) {
          final isVerified = infoData['isEmailConfirmed'] as bool? ?? false;
          // Keep existing cached user if available, just update email verification
          if (state.user != null) {
            state = state.copyWith(
              isEmailVerified: isVerified,
            );
          } else {
            // No cached user and profile API failed — log out
            state = AuthState.initial;
          }
        } else {
          // Both APIs failed — keep cached state if any (offline scenario)
          if (state.user == null) {
            state = AuthState.initial;
          }
        }
      }
    } catch (e) {
      // On error (e.g. no internet), keep cached state if available
      if (state.user == null) {
        state = AuthState.initial;
      }
    }
  }

  /// Set the authenticated session (called from screen controllers)
  void setSession(AuthUser user) {
    state = AuthState(
      user: user,
      isAuthenticated: true,
      isEmailVerified: user.emailVerified,
    );
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      // Setting state to initial is enough:
      // • All user-scoped providers watch authProvider via .select() and
      //   will auto-reset when isAuthenticated flips to false.
      // • The router's refreshListenable picks up the state change and
      //   redirects to the login screen immediately.
      state = AuthState.initial;
    }
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  // Pass ref so AuthNotifier can invalidate all user-scoped providers on logout.
  return AuthNotifier(authService, ref);
});

/// Auth service provider (for dependency injection)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthServiceImpl();
});
