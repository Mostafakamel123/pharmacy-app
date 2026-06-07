// ignore_for_file: use_super_parameters,


import 'package:Elaaj/core/constants/app_constants.dart';
import 'package:Elaaj/core/helpers/local_storage_helper.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/auth/view/screens/email_verification_screen.dart';
import 'package:Elaaj/features/auth/view/screens/forgot_password_screen.dart';
import 'package:Elaaj/features/auth/view/screens/login_screen.dart';
import 'package:Elaaj/features/auth/view/screens/register_screen.dart';
import 'package:Elaaj/features/auth/view/screens/reset_password_screen.dart';
import 'package:Elaaj/features/chat/view/screens/chat_screen.dart';
import 'package:Elaaj/features/chat/view/screens/chats_list_screen.dart';
import 'package:Elaaj/features/navigation/widgets/premium_nav_shell.dart';
import 'package:Elaaj/features/onboarding/view/onboarding_screen.dart';
import 'package:Elaaj/features/prescription/view/screens/my_prescriptions_screen.dart';
import 'package:Elaaj/features/prescription/view/screens/searching_pharmacies_screen.dart';
import 'package:Elaaj/features/prescription/view/screens/upload_prescription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// A [ChangeNotifier] that watches a Riverpod provider and notifies
/// GoRouter whenever the provider's value changes.
///
/// This is more robust than listening to a [StateNotifier]'s stream directly
/// because it survives provider invalidation/recreation (e.g. after logout).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(ProviderListenable<AuthState> listenable, Ref ref) {
    ref.listen<AuthState>(listenable, (_, __) => notifyListeners());
  }
}

// App Router Configuration Provider
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(authProvider, ref);

  // Keep refreshNotifier alive as long as routerProvider is alive.
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      
      // Check onboarding completion synchronously
      final isOnboardingComplete = LocalStorageHelper.getBoolSync(
        AppConstants.onboardingCompleteKey,
      );

      final location = state.uri.path;

      // 1. If onboarding is not complete, force them to onboarding page
      if (!isOnboardingComplete) {
        if (location == AppRoutes.onboarding) {
          return null; // Stay on onboarding
        }
        return AppRoutes.onboarding;
      }

      // 2. Onboarding is complete. Evaluate authentication
      final isAuthRoute = location.startsWith('/auth');

      if (!isAuthenticated) {
        // Unauthenticated users can only visit auth pages
        if (isAuthRoute) {
          return null; // Allow viewing login/register etc.
        }
        // Redirect any other route to login
        return AppRoutes.login;
      }

      // 3. User is authenticated.
      // If they are on an auth route or onboarding, redirect to home
      if (isAuthRoute || location == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      // Allow all other routes
      return null;
    },
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
        // Email is passed via extra from ForgotPasswordScreen
        final email = state.extra as String? ?? '';
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


    // Prescription Chat Screen (polling-based, /api/Chat endpoints)
    GoRoute(
      path: AppRoutes.prescriptionChat,
      name: 'prescriptionChat',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return ChatScreen(
          prescriptionId: args['prescriptionId'] as String? ?? '',
          otherUserId: args['otherUserId'] as String? ?? '',
          currentUserId: args['currentUserId'] as String? ?? '',
          isPharmacy: args['isPharmacy'] as bool? ?? false,
          pharmacyId: args['pharmacyId'] as String?,
          otherUserName: args['otherUserName'] as String? ?? 'Chat',
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
    GoRoute(
      path: AppRoutes.myPrescriptions,
      name: 'myPrescriptions',
      builder: (context, state) => const MyPrescriptionsScreen(),
    ),
  ],
);
});
