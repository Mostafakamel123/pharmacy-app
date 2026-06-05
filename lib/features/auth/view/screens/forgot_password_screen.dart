// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Elaaj/core/routing/app_routes.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/auth/view/widgets/auth_text_field.dart';
import 'package:Elaaj/features/auth/view/widgets/auth_button.dart';

// Compile-time constant for Regex
final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail(String value) {
    if (!_emailRegex.hasMatch(value)) {
      setState(() => _emailError = 'Please enter a valid email');
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (!_validateEmail(email)) return;

    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    final success = await ref
        .read(authProvider.notifier)
        .sendPasswordResetEmail(email);

    if (success && mounted) {
      // Navigate to reset password screen, passing the email
      context.push(AppRoutes.resetPassword, extra: email);
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
              // Align(
              //   alignment: Alignment.topLeft,
              //   child: IconButton(
              //     icon: Icon(
              //       Icons.arrow_back_ios_new_rounded,
              //       color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
              //       size: 20,
              //     ),
              //     onPressed: () => context.pop(),
              //     padding: EdgeInsets.zero,
              //     constraints: const BoxConstraints(),
              //   ),
              // ),
              const SizedBox(height: 20),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 40,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Forgot Password?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your email address and we\'ll send you a verification code to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                ),
              ),
              const SizedBox(height: 100),

              AuthTextField(
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                errorText: _emailError,
                onChanged: (value) => _validateEmail(value),
              ),
              const SizedBox(height: 24),

              // Error Banner
              const _ForgotErrorBanner(),

              // Submit Button
              _ForgotSubmitButton(onPressed: _handleSubmit),
              const SizedBox(height: 20),

              // Back to login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remember your password ?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Extracted Widgets for Performance ---

class _ForgotSubmitButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _ForgotSubmitButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    return AuthButton(
      text: 'Send Verification Code',
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

class _ForgotErrorBanner extends ConsumerWidget {
  const _ForgotErrorBanner();

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
