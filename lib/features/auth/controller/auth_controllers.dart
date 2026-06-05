import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/network/failure.dart';
import 'package:Elaaj/features/auth/service/auth_service.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';

/// Helper to extract user-friendly messages from Failure objects
String getErrorMessage(Object error) {
  if (error is ValidationFailure) {
    final errors = error.errors;
    if (errors == null || errors.isEmpty) {
      return error.message;
    }

    final errorStrings = <String>[];
    errors.forEach((field, messages) {
      if (messages.isNotEmpty) {
        if (field.toLowerCase() == 'general') {
          errorStrings.add(messages.join(', '));
        } else {
          errorStrings.add('$field: ${messages.join(', ')}');
        }
      }
    });

    if (errorStrings.isEmpty) {
      return error.message;
    }
    return errorStrings.join('\n');
  }
  if (error is Failure) {
    return error.message;
  }
  return error.toString();
}

// ── LOGIN CONTROLLER ─────────────────────────────────────────────────────────

class LoginController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(email, password);
      if (user != null) {
        ref.read(authProvider.notifier).setSession(user);
      } else {
        throw AppFailure(
          message: 'Login failed. Please check your credentials.',
          code: 'LOGIN_FAILED',
        );
      }
    });
    return !state.hasError;
  }
}

final loginControllerProvider =
    AutoDisposeAsyncNotifierProvider<LoginController, void>(() {
  return LoginController();
});

// ── REGISTER CONTROLLER ──────────────────────────────────────────────────────

class RegisterController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<bool> register(
    String fullName,
    String email,
    String password,
    String confirmPassword,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.register(fullName, email, password, confirmPassword);
    });
    return !state.hasError;
  }
}

final registerControllerProvider =
    AutoDisposeAsyncNotifierProvider<RegisterController, void>(() {
  return RegisterController();
});

// ── FORGOT PASSWORD CONTROLLER ────────────────────────────────────────────────

class ForgotPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<bool> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.forgotPassword(email);
    });
    return !state.hasError;
  }
}

final forgotPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ForgotPasswordController, void>(() {
  return ForgotPasswordController();
});

// ── RESET PASSWORD CONTROLLER ─────────────────────────────────────────────────

class ResetPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<bool> resetPassword(
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(otp, newPassword, confirmPassword);
    });
    return !state.hasError;
  }

  Future<bool> resendCode(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.forgotPassword(email);
    });
    return !state.hasError;
  }
}

final resetPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ResetPasswordController, void>(() {
  return ResetPasswordController();
});

// ── EMAIL VERIFICATION CONTROLLER ──────────────────────────────────────────────

class EmailVerificationController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<bool> verifyEmail(String email, String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.verifyEmail(email, code);
      
      // Update global session with verification status if already logged in
      final currentAuth = ref.read(authProvider);
      if (currentAuth.user != null) {
        ref.read(authProvider.notifier).setSession(
              currentAuth.user!.copyWith(emailVerified: true),
            );
      }
    });
    return !state.hasError;
  }

  Future<bool> resendVerification(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.resendConfirmationEmail(email);
    });
    return !state.hasError;
  }
}

final emailVerificationControllerProvider =
    AutoDisposeAsyncNotifierProvider<EmailVerificationController, void>(() {
  return EmailVerificationController();
});
