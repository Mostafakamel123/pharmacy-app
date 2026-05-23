import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/network/failure.dart';
import 'package:pharmacy_app/features/auth/model/auth_user.dart';
import 'package:pharmacy_app/features/auth/service/auth_service.dart';

/// Authentication state
class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isEmailVerified;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isEmailVerified = false,
  });

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isEmailVerified,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  /// Initial state
  static const initial = AuthState();

  /// Loading state
  static const loading = AuthState(isLoading: true);
}

/// Auth notifier using StateNotifier (following existing pattern)
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial) {
    // Check if user is already logged in on initialization
    _checkAuthStatus();
  }

  /// Check authentication status from local storage
  Future<void> _checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Get profile info from API
      final profileData = await _authService.getProfileInfo();

      if (profileData != null) {
        final user = AuthUser.fromJson(profileData);
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isEmailVerified: user.emailVerified,
          isLoading: false,
        );
      } else {
        // No user from API, check local storage
        state = AuthState.initial;
      }
    } catch (e) {
      // On error, assume not authenticated
      state = AuthState.initial;
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await _authService.login(email, password);

      if (user != null) {
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isEmailVerified: user.emailVerified,
          isLoading: false,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Please check your credentials.',
      );
      return false;
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Register new user
  Future<bool> register(String fullName, String email, String password, String confirmPassword) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.register(fullName, email, password, confirmPassword);

      // Registration successful - user needs to verify email before logging in
      state = state.copyWith(
        isLoading: false,
      );
      return true;
    } on ValidationFailure catch (e) {
      // Extract field-specific errors
      final errorMessage = e.errors != null 
          ? e.getAllErrorsAsString()
          : e.message;
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      state = AuthState.initial;
    }
  }

  /// Send forgot password email
  Future<bool> forgotPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Alias for forgotPassword to maintain compatibility with UI
  Future<bool> sendPasswordResetEmail(String email) async {
    return forgotPassword(email);
  }

  /// Resend verification email
  Future<bool> resendConfirmationEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.resendConfirmationEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Alias for resendConfirmationEmail to maintain compatibility with UI
  Future<bool> sendVerificationEmail(String email) async {
    return resendConfirmationEmail(email);
  }

  /// Reset password with email and reset code
  Future<bool> resetPassword(String email, String resetCode, String newPassword) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.resetPassword(email, resetCode, newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Verify email with email and code (OTP)
  Future<bool> verifyEmail(String email, String code) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.verifyEmail(email, code);

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(emailVerified: true),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Verify email with userId and code
  Future<bool> confirmEmail(String userId, String code) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.confirmEmail(userId, code);

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(emailVerified: true),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Get profile info from API to check verification status
      final profileData = await _authService.getProfileInfo();
      
      if (profileData != null) {
        final user = AuthUser.fromJson(profileData);
        final isVerified = user.emailVerified;
        state = state.copyWith(
          user: user,
          isLoading: false,
        );
        return isVerified;
      }
      
      state = state.copyWith(isLoading: false);
      return false;
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

/// Auth service provider (for dependency injection)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthServiceImpl();
});