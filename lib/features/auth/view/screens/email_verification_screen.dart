// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/routing/app_routes.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/auth/controller/auth_providers.dart';
import 'package:pharmacy_app/features/auth/view/widgets/auth_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isVerified = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _handleResendEmail() async {
    final email = widget.email;
    if (email != null) {
      await ref.read(authProvider.notifier).sendVerificationEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyNow() async {
    final isVerified = await ref.read(authProvider.notifier).checkEmailVerification();
    if (mounted) {
      if (isVerified) {
        setState(() => _isVerified = true);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not yet verified. Please check your inbox.'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed ref.watch(authProvider) from here!
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

              if (_isChecking) ...[
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  // 2. Added const to alwaysStoppedAnimation 
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Checking Verification...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait while we check your email verification status.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
              ] else if (!_isVerified) ...[
                Container(
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
                  'We\'ve sent a verification link to\n$email',
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
                          'Click the link in the email or tap "I\'ve Verified" below after completing verification.',
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

                // Extracted Error Banner
                const _EmailVerifyErrorBanner(),
                
                // Extracted Buttons
                _VerifyButton(onPressed: _handleVerifyNow),
                const SizedBox(height: 16),

                _ResendButton(onPressed: _handleResendEmail),
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
                Container(
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

class _VerifyButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _VerifyButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    return AuthButton(
      text: 'I\'ve Verified',
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

class _ResendButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _ResendButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    return AuthButton(
      text: 'Resend Email',
      isLoading: isLoading,
      isOutlined: true,
      onPressed: onPressed,
    );
  }
}

class _EmailVerifyErrorBanner extends ConsumerWidget {
  const _EmailVerifyErrorBanner();

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