// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/routing/app_routes.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/auth/controller/auth_providers.dart';
import 'package:pharmacy_app/features/auth/view/widgets/auth_text_field.dart';
import 'package:pharmacy_app/features/auth/view/widgets/auth_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  /// The email the OTP was sent to (passed from ForgotPasswordScreen via route extra)
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isSuccess = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateOtp(String value) {
    if (value.isEmpty || value.length < 4) {
      setState(() => _otpError = 'Please enter the verification code');
      return false;
    }
    setState(() => _otpError = null);
    return true;
  }

  bool _validatePassword(String value) {
    if (value.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return false;
    }
    setState(() => _passwordError = null);
    return true;
  }

  bool _validateConfirmPassword(String value) {
    if (value != _passwordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return false;
    }
    setState(() => _confirmPasswordError = null);
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validateOtp(_otpController.text.trim())) return;
    if (!_validatePassword(_passwordController.text)) return;
    if (!_validateConfirmPassword(_confirmPasswordController.text)) return;

    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    final success = await ref.read(authProvider.notifier).resetPassword(
          _otpController.text.trim(),
          _passwordController.text,
          _confirmPasswordController.text,
        );

    if (success && mounted) {
      setState(() => _isSuccess = true);
    }
  }

  Future<void> _handleResendCode() async {
    ref.read(authProvider.notifier).clearError();
    final success = await ref
        .read(authProvider.notifier)
        .sendPasswordResetEmail(widget.email);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'A new verification code has been sent to your email.'
                : 'Failed to resend code. Please try again.',
          ),
          backgroundColor: success ? AppColors.primaryGreen : AppColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 20),

              if (!_isSuccess) ...[
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 40,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the verification code sent to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // OTP / Verification Code field
                AuthTextField(
                  label: 'Verification Code',
                  hint: 'Enter the code from your email',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  controller: _otpController,
                  errorText: _otpError,
                  onChanged: (value) => _validateOtp(value),
                ),
                const SizedBox(height: 20),

                AuthTextField(
                  label: 'New Password',
                  hint: 'Create a strong password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  errorText: _passwordError,
                  onChanged: (value) => _validatePassword(value),
                ),
                const SizedBox(height: 20),

                AuthTextField(
                  label: 'Confirm New Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _confirmPasswordController,
                  errorText: _confirmPasswordError,
                  onChanged: (value) => _validateConfirmPassword(value),
                ),
                const SizedBox(height: 20),

                // Password requirements hint
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password requirements:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _RequirementItem(
                        text: 'At least 6 characters',
                        isValid: _passwordController.text.length >= 6,
                        isDark: isDark,
                      ),
                      _RequirementItem(
                        text: 'Passwords match',
                        isValid: _confirmPasswordController.text == _passwordController.text &&
                            _passwordController.text.isNotEmpty,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error Banner
                const _ResetErrorBanner(),

                // Reset Button
                _ResetPasswordButton(onPressed: _handleSubmit),
                const SizedBox(height: 16),

                // Resend code option
                Center(
                  child: TextButton(
                    onPressed: _handleResendCode,
                    child: Text(
                      'Didn\'t receive a code? Resend',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Password Reset!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your password has been successfully updated. You can now sign in with your new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                AuthButton(
                  text: 'Go to Login',
                  isLoading: false,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- Extracted Widgets for Performance ---

class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isValid;
  final bool isDark;

  const _RequirementItem({
    required this.text,
    required this.isValid,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isValid ? AppColors.primaryGreen : (isDark ? DarkColors.textHint : LightColors.textHint),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppColors.primaryGreen : (isDark ? DarkColors.textHint : LightColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _ResetPasswordButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    return AuthButton(
      text: 'Reset Password',
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

class _ResetErrorBanner extends ConsumerWidget {
  const _ResetErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(authProvider.select((s) => s.error));
    if (error == null) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.accentRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(error, style: const TextStyle(color: AppColors.accentRed, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}