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

  /// Check authentication status
  Future<void> _checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true);
      final user = await _authService.getCurrentUser();

      if (user != null) {
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isEmailVerified: user.isEmailVerified,
          isLoading: false,
        );
      } else {
        state = AuthState.initial;
      }
    } catch (e) {
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
          isEmailVerified: user.isEmailVerified,
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
  Future<bool> register(String name, String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await _authService.register(name, email, password);

      if (user != null) {
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isEmailVerified: user.isEmailVerified,
          isLoading: false,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
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

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.sendPasswordResetEmail(email);
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

  /// Reset password with token
  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.resetPassword(token, newPassword);
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

  /// Resend verification email
  Future<bool> resendVerificationEmail() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.resendVerificationEmail();
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

  /// Verify email with token
  Future<bool> verifyEmail(String token) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.verifyEmail(token);

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          isEmailVerified: true,
          user: state.user!.copyWith(isEmailVerified: true),
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

  /// Send verification email to specified email address
  Future<bool> sendVerificationEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.resendVerificationEmail();
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

  /// Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Get current user to check verification status
      final user = await _authService.getCurrentUser();
      
      if (user != null && user.isEmailVerified) {
        state = state.copyWith(
          isEmailVerified: true,
          user: user,
          isLoading: false,
        );
        return true;
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