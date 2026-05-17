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
import 'package:pharmacy_app/features/posts/view/post_details_screen.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';
import 'package:pharmacy_app/features/posts/view/create_post_screen.dart';
import 'package:pharmacy_app/features/pharmacies/view/pharmacy_details_screen.dart';
import 'package:pharmacy_app/features/pharmacies/view/nearby_pharmacies_screen.dart';
import 'package:pharmacy_app/features/profile/view/profile_screen.dart';
import 'package:pharmacy_app/features/profile/view/edit_profile_screen.dart';
import 'package:pharmacy_app/features/profile/view/my_posts_screen.dart';
import 'package:pharmacy_app/features/profile/view/saved_posts_screen.dart';
import 'package:pharmacy_app/features/posts/view/posts_feed_screen.dart';
import 'app_routes.dart';

// ============================================================================
// PERFORMANCE-OPTIMIZED PAGE TRANSITIONS
// ============================================================================
// Using custom page transitions for smooth 60fps navigation
// - FadeThroughTransition: Primary transition (fade + slight scale)
// - SlideTransition: For back navigation
// - All transitions are GPU-accelerated and lightweight
// ============================================================================

/// Custom fade-through transition with subtle scale
/// Optimized for performance with CurvedAnimation
Widget _fadeThroughTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ),
    child: ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  );
}

/// Slide from right transition for push navigation
Widget _slideRightTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.05, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    )),
    child: FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: child,
    ),
  );
}

/// Slide to right transition for pop navigation
Widget _slideLeftTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.05, 0.0),
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInCubic,
    )),
    child: FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInCubic,
      ),
      child: child,
    ),
  );
}

/// Shared transition duration - short and snappy for premium feel
const Duration _kTransitionDuration = Duration(milliseconds: 250);

// ============================================================================
// CUSTOM PAGE CLASSES FOR CONSISTENT TRANSITIONS
// ============================================================================

/// Base custom page with optimized transitions
class FadeThroughPage<T> extends CustomTransitionPage<T> {
  FadeThroughPage({
    required super.child,
    super.name,
    super.arguments,
    super.key,
    String? restorationId,
  }) : super(
          transitionsBuilder: _fadeThroughTransition,
          transitionDuration: _kTransitionDuration,
          reverseTransitionDuration: _kTransitionDuration,
          maintainState: true,
          fullscreenDialog: false,
        );
}

/// Slide page for detailed views
class SlidePage<T> extends CustomTransitionPage<T> {
  final bool isPush;

  SlidePage({
    required super.child,
    super.name,
    super.arguments,
    super.key,
    String? restorationId,
    this.isPush = true,
  }) : super(
          transitionsBuilder: isPush ? _slideRightTransition : _slideLeftTransition,
          transitionDuration: _kTransitionDuration,
          reverseTransitionDuration: _kTransitionDuration,
          maintainState: true,
          fullscreenDialog: false,
        );
}

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

// ============================================================================
// APP ROUTER CONFIGURATION WITH OPTIMIZED TRANSITIONS
// ============================================================================
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.onboarding,
  errorBuilder: (context, state) => const NotFoundScreen(),
  // Enable fast route resolution
  redirect: (context, state) {
    // Add any global redirect logic here
    return null;
  },
  routes: [
    // Onboarding Screen - Full fade transition
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => FadeThroughPage(
        child: const OnboardingScreen(),
        name: 'onboarding',
      ),
    ),

    // Auth Routes
    GoRoute(
      path: AppRoutes.auth,
      name: 'auth',
      redirect: (context, state) => AppRoutes.login,
    ),

    // Login Screen - Slide transition
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) => SlidePage(
        child: const LoginScreen(),
        name: 'login',
      ),
    ),

    // Register Screen - Slide transition
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      pageBuilder: (context, state) => SlidePage(
        child: const RegisterScreen(),
        name: 'register',
      ),
    ),

    // Forgot Password Screen
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      pageBuilder: (context, state) => SlidePage(
        child: const ForgotPasswordScreen(),
        name: 'forgotPassword',
      ),
    ),

    // Reset Password Screen
    GoRoute(
      path: AppRoutes.resetPassword,
      name: 'resetPassword',
      pageBuilder: (context, state) {
        final token = state.pathParameters['token']!;
        return SlidePage(
          child: ResetPasswordScreen(token: token),
          name: 'resetPassword',
        );
      },
    ),

    // Email Verification Screen
    GoRoute(
      path: AppRoutes.emailVerification,
      name: 'emailVerification',
      pageBuilder: (context, state) {
        final email = state.extra as String?;
        return SlidePage(
          child: EmailVerificationScreen(email: email),
          name: 'emailVerification',
        );
      },
    ),

    // Home Route - Main shell with fade transition
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      pageBuilder: (context, state) => FadeThroughPage(
        child: const PremiumNavShell(),
        name: 'home',
      ),
    ),

    // Chat Routes
    GoRoute(
      path: AppRoutes.chats,
      name: 'chats',
      pageBuilder: (context, state) => SlidePage(
        child: const ChatsListScreen(),
        name: 'chats',
      ),
    ),
    GoRoute(
      path: AppRoutes.chat,
      name: 'chat',
      pageBuilder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final pharmacyName = state.extra as String?;
        return SlidePage(
          child: ChatConversationScreen(
            chatId: chatId,
            pharmacyName: pharmacyName,
          ),
          name: 'chat',
        );
      },
    ),

    // Prescription Routing Routes
    GoRoute(
      path: AppRoutes.uploadPrescription,
      name: 'uploadPrescription',
      pageBuilder: (context, state) => SlidePage(
        child: const UploadPrescriptionScreen(),
        name: 'uploadPrescription',
      ),
    ),
    GoRoute(
      path: AppRoutes.searchingPharmacies,
      name: 'searchingPharmacies',
      pageBuilder: (context, state) => SlidePage(
        child: const SearchingPharmaciesScreen(),
        name: 'searchingPharmacies',
      ),
    ),

    // Posts Routes
    GoRoute(
      path: '/posts',
      name: 'posts',
      pageBuilder: (context, state) => SlidePage(
        child: const PostsFeedScreen(),
        name: 'posts',
      ),
    ),
    GoRoute(
      path: '/post/:postId',
      name: 'postDetails',
      pageBuilder: (context, state) {
        // Post details would need post data passed via extra
        final post = state.extra as PostModel?;
        if (post == null) {
          return FadeThroughPage(
            child: const SizedBox.shrink(),
            name: 'postDetails',
          );
        }
        return SlidePage(
          child: PostDetailsScreen(post: post),
          name: 'postDetails',
        );
      },
    ),
    GoRoute(
      path: '/create-post',
      name: 'createPost',
      pageBuilder: (context, state) => SlidePage(
        child: const CreatePostScreen(),
        name: 'createPost',
      ),
    ),

    // Pharmacy Routes
    GoRoute(
      path: '/pharmacies',
      name: 'pharmacies',
      pageBuilder: (context, state) => SlidePage(
        child: const NearbyPharmaciesScreen(),
        name: 'pharmacies',
      ),
    ),
    GoRoute(
      path: '/pharmacy/:pharmacyId',
      name: 'pharmacyDetails',
      pageBuilder: (context, state) {
        final pharmacy = state.extra;
        if (pharmacy == null) {
          return FadeThroughPage(
            child: const SizedBox.shrink(),
            name: 'pharmacyDetails',
          );
        }
        return SlidePage(
          child: PharmacyDetailsScreen(pharmacy: pharmacy),
          name: 'pharmacyDetails',
        );
      },
    ),

    // Profile Routes
    GoRoute(
      path: '/profile',
      name: 'profile',
      pageBuilder: (context, state) => SlidePage(
        child: const ProfileScreen(),
        name: 'profile',
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'editProfile',
      pageBuilder: (context, state) => SlidePage(
        child: const EditProfileScreen(),
        name: 'editProfile',
      ),
    ),
    GoRoute(
      path: '/my-posts',
      name: 'myPosts',
      pageBuilder: (context, state) => SlidePage(
        child: const MyPostsScreen(),
        name: 'myPosts',
      ),
    ),
    GoRoute(
      path: '/saved-posts',
      name: 'savedPosts',
      pageBuilder: (context, state) => SlidePage(
        child: const SavedPostsScreen(),
        name: 'savedPosts',
      ),
    ),
  ],
);

