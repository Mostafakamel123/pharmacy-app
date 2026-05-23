// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/features/navigation/widgets/premium_nav_shell.dart';
import 'package:pharmacy_app/features/onboarding/view/onboarding_screen.dart';
import 'package:pharmacy_app/features/auth/view/screens/login_screen.dart';
import 'package:pharmacy_app/features/auth/view/screens/register_screen.dart';
import 'package:pharmacy_app/features/auth/view/screens/forgot_password_screen.dart';
import 'package:pharmacy_app/features/auth/view/screens/reset_password_screen.dart';
import 'package:pharmacy_app/features/auth/view/screens/email_verification_screen.dart';
import 'package:pharmacy_app/features/chat/view/screens/chats_list_screen.dart';
import 'package:pharmacy_app/features/chat/view/screens/chat_conversation_screen.dart';
import 'package:pharmacy_app/features/prescription/view/screens/upload_prescription_screen.dart';
import 'package:pharmacy_app/features/prescription/view/screens/searching_pharmacies_screen.dart';
import 'app_routes.dart';

// Simple 404 error page
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Page Not Found'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// App Router Configuration
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.onboarding,
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    // Onboarding Screen
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    
    // Auth Routes
    GoRoute(
      path: AppRoutes.auth,
      name: 'auth',
      redirect: (context, state) => AppRoutes.login,
    ),
    
    // Login Screen
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    
    // Register Screen
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Forgot Password Screen
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    
    // Reset Password Screen
    GoRoute(
      path: AppRoutes.resetPassword,
      name: 'resetPassword',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return ResetPasswordScreen(email: email);
      },
    ),
    
    // Email Verification Screen
    GoRoute(
      path: AppRoutes.emailVerification,
      name: 'emailVerification',
      builder: (context, state) {
        final email = state.extra as String?;
        return EmailVerificationScreen(email: email);
      },
    ),
    
    // Home Route
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const PremiumNavShell(),
    ),
    
    // Chat Routes
    GoRoute(
      path: AppRoutes.chats,
      name: 'chats',
      builder: (context, state) => const ChatsListScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      name: 'chat',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final pharmacyName = state.extra as String?;
        return ChatConversationScreen(
          chatId: chatId,
          pharmacyName: pharmacyName,
        );
      },
    ),
    
    // Prescription Routing Routes
    GoRoute(
      path: AppRoutes.uploadPrescription,
      name: 'uploadPrescription',
      builder: (context, state) => const UploadPrescriptionScreen(),
    ),
    GoRoute(
      path: AppRoutes.searchingPharmacies,
      name: 'searchingPharmacies',
      builder: (context, state) => const SearchingPharmaciesScreen(),
    ),
  ],
);
