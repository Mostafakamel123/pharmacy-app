// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/utils/user_role.dart';
import 'package:pharmacy_app/features/navigation/widgets/premium_nav_shell.dart';
import 'package:pharmacy_app/features/onboarding/view/onboarding_screen.dart';
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
    // Splash Screen
   
    
    // Onboarding Screen
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    
    // Auth Routes (placeholder for future implementation)
    GoRoute(
      path: AppRoutes.auth,
      name: 'auth',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Auth Screen')),
      ),
      routes: [
        GoRoute(
          path: 'login',
          name: 'login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login Screen')),
          ),
        ),
        GoRoute(
          path: 'register',
          name: 'register',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Register Screen')),
          ),
        ),
      ],
    ),
    
    // Home Route - Premium Navigation Shell
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const PremiumNavShell(
        userRole: UserRole.patient, // Patient view with home screen
      ),
    ),
  ],
);
