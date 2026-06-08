/// Unified navigation configuration for all users
/// 
/// The app now has a single navigation flow regardless of user type.
/// Pharmacy management is handled through pharmacy mode toggle.
// ignore_for_file: unused_element

library;

import 'package:Elaaj/features/chat/view/screens/chats_list_screen.dart';
import 'package:Elaaj/features/home/view/home_screen.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/features/pharmacy_mode/view/screens/pharmacy_orders_screen.dart';
import 'package:Elaaj/features/pharmacy_mode/view/screens/pharmacy_profile_screen.dart';
import 'package:Elaaj/features/pharmacy_mode/view/screens/pharmacy_accepted_prescriptions_screen.dart';
import 'package:Elaaj/features/posts/view/create_post_screen.dart';
import 'package:Elaaj/features/posts/view/posts_feed_screen.dart';
import 'package:Elaaj/features/profile/view/profile_screen.dart';
import 'package:Elaaj/features/prescription/view/screens/my_prescriptions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



/// Navigation item configuration
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget Function(WidgetRef ref) builder;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.builder,
    required this.route,
  });
}

/// Unified navigation items for all users
class UserNavItems {
  UserNavItems._();

  static List<NavItem> items(WidgetRef ref) {
    final pharmacyModeState = ref.watch(pharmacyModeProvider);
    final isPharmacyMode = pharmacyModeState.isPharmacyMode;

    if (isPharmacyMode) {
      return [
        NavItem(
          label: 'Pharmacy Profile',
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront,
          builder: (ref) => const PharmacyProfileScreen(),
          route: '/pharmacy/profile',
        ),
        NavItem(
          label: 'Prescriptions',
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long,
          builder: (ref) => const PharmacyAcceptedPrescriptionsScreen(),
          route: '/pharmacy/accepted-prescriptions',
        ),
        NavItem(
          label: 'Posts',
          icon: Icons.article_outlined,
          activeIcon: Icons.article,
          builder: (ref) => const PostsFeedScreen(),
          route: '/posts',
        ),
        NavItem(
          label: 'Orders',
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          builder: (ref) => const PharmacyOrdersScreen(),
          route: '/pharmacy/orders',
        ),
      ];
    }

    return [
      NavItem(
        label: 'Home',
        icon: Icons.medical_services_outlined,
        activeIcon: Icons.medical_services,
        builder: (ref) => const PatientHomeScreen(),
        route: '/home',
      ),
      NavItem(
        label: 'Posts',
        icon: Icons.article_outlined,
        activeIcon: Icons.article,
        builder: (ref) => const PostsFeedScreen(),
        route: '/posts',
      ),
      NavItem(
        label: 'Prescriptions',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        builder: (ref) => const MyPrescriptionsScreen(),
        route: '/my-prescriptions',
      ),
      NavItem(
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        builder: (ref) => const ProfileScreen(),
        route: '/profile',
      ),
    ];
  }

  /// Center FAB configuration
  static final fabNavItem = NavItem(
    label: 'Add',
    icon: Icons.add,
    activeIcon: Icons.add,
    builder: _buildAdd,
    route: '/add',
  );

  // Screen builders
  static Widget _buildHome() => const PatientHomeScreen();
  static Widget _buildPosts() => const PostsFeedScreen();
  static Widget _buildChat() => const ChatsListScreen();
  static Widget _buildProfile() => const ProfileScreen();
  static Widget _buildAdd(WidgetRef ref) => const CreatePostScreen();

  /// Get screen by index (accounts for FAB at index 2)
  static Widget getScreenByIndex(int index, WidgetRef ref) {
    if (index < 0 || index >= items(ref).length) {
      return const SizedBox.shrink();
    }
    return items(ref)[index].builder(ref);
  }

  /// Get route by index
  static String getRouteByIndex(int index, WidgetRef ref) {
    if (index < 0 || index >= items(ref).length) {
      return '/';
    }
    return items(ref)[index].route;
  }
}
