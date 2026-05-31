// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/routing/app_routes.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/auth/controller/auth_providers.dart';
import 'package:pharmacy_app/features/auth/view/widgets/auth_button.dart';
import 'package:pharmacy_app/features/auth/view/widgets/auth_text_field.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isVerified = false;
  String? _otpError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  bool _validateOtp(String value) {
    if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
      setState(() => _otpError = 'Please enter a valid 6-digit code');
      return false;
    }
    setState(() => _otpError = null);
    return true;
  }

  Future<void> _handleResendEmail() async {
    final email = widget.email;
    if (email != null) {
      await ref.read(authProvider.notifier).sendVerificationEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent! Please check your inbox.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyNow() async {
    final email = widget.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not available. Please try again.'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    if (!_validateOtp(_otpController.text.trim())) return;

    final success = await ref.read(authProvider.notifier).verifyEmail(
      email,
      _otpController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() => _isVerified = true);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid verification code. Please try again.'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = widget.email ?? 'your email';

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

              if (!_isVerified) ...[
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 40,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'ve sent a 6-digit verification code to\n$email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter the 6-digit code from your email or tap "Resend Code" if you didn\'t receive it.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // OTP Input Field
                AuthTextField(
                  label: 'Verification Code',
                  hint: 'Enter 6-digit code',
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  controller: _otpController,
                  errorText: _otpError,
                  maxLength: 6,
                ),
                const SizedBox(height: 24),

                // Error Banner
                const _VerificationErrorBanner(),

                // Verify Button
                _VerifyEmailButton(onPressed: _handleVerifyNow),
                const SizedBox(height: 16),

                // Resend Button
                _ResendCodeButton(onPressed: _handleResendEmail),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? DarkColors.textHint : LightColors.textHint,
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
                  'Email Verified!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your email has been successfully verified. You\'re all set!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                AuthButton(
                  text: 'Continue to Home',
                  isLoading: false,
                  onPressed: () => context.go(AppRoutes.home),
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

class _VerifyEmailButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _VerifyEmailButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    return AuthButton(
      text: 'Verify Email',
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

class _ResendCodeButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _ResendCodeButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    return AuthButton(
      text: 'Resend Code',
      isLoading: isLoading,
      isOutlined: true,
      onPressed: onPressed,
    );
  }
}

class _VerificationErrorBanner extends ConsumerWidget {
  const _VerificationErrorBanner();

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
                child: Text(
                  error,
                  style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
