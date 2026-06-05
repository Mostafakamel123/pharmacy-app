import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Elaaj/core/routing/app_routes.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/auth/view/widgets/auth_text_field.dart';
import 'package:Elaaj/features/auth/view/widgets/auth_button.dart';

// Using the same top-level regex
final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // Clear error on dispose to prevent leaks
    ref.read(authProvider.notifier).clearError();
    super.dispose();
  }

  bool _validateFullName(String value) {
    if (value.trim().length < 2) {
      setState(() => _fullNameError = 'Name must be at least 2 characters');
      return false;
    }
    setState(() => _fullNameError = null);
    return true;
  }

  bool _validateEmail(String value) {
    if (!_emailRegex.hasMatch(value)) {
      setState(() => _emailError = 'Please enter a valid email');
      return false;
    }
    setState(() => _emailError = null);
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

  Future<void> _handleRegister() async {
    if (!_validateFullName(_fullNameController.text.trim())) return;
    if (!_validateEmail(_emailController.text.trim())) return;
    if (!_validatePassword(_passwordController.text)) return;
    if (!_validateConfirmPassword(_confirmPasswordController.text)) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          _fullNameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _confirmPasswordController.text,
        );

    if (success && mounted) {
      // After successful registration, navigate to email verification or login
      // According to Elaaj API flow, user must verify email before logging in
      context.go(AppRoutes.emailVerification, extra: _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed ref.watch for authProvider from here!
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
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
                //     onPressed: () => context.go(AppRoutes.login),
                //     padding: EdgeInsets.zero,
                //     constraints: const BoxConstraints(),
                //   ),
                // ),
                // const SizedBox(height: 20),
                // // Logo/Title
               SizedBox(
                  width: 150,
                  height:150,
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // const SizedBox(height: 24),
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign up to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 15),

                AuthTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                  controller: _fullNameController,
                  errorText: _fullNameError,
                  onChanged: (value) => _validateFullName(value),
                ),
                const SizedBox(height: 5),

                AuthTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  errorText: _emailError,
                  onChanged: (value) => _validateEmail(value),
                ),
                const SizedBox(height: 5),

                AuthTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  errorText: _passwordError,
                  onChanged: (value) => _validatePassword(value),
                ),
                const SizedBox(height: 5),

                AuthTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _confirmPasswordController,
                  errorText: _confirmPasswordError,
                  onChanged: (value) => _validateConfirmPassword(value),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() => _acceptTerms = value ?? false);
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _acceptTerms = !_acceptTerms);
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Extracted Error Banner
                const _RegisterAuthErrorBanner(),
                
                // Extracted Register Button
                _RegisterButton(onPressed: _handleRegister),
                
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(authProvider.notifier).clearError();
                        context.push(AppRoutes.login);
                      },
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
      ),
    );
  }
}

class _RegisterButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _RegisterButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    return AuthButton(
      text: 'Create Account',
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

class _RegisterAuthErrorBanner extends ConsumerWidget {
  const _RegisterAuthErrorBanner();

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
            border: Border.all(
              color: AppColors.accentRed.withOpacity(0.3),
            ),
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
