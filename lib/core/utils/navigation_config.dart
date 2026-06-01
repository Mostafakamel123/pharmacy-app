/// Unified navigation configuration for all users
/// 
/// The app now has a single navigation flow regardless of user type.
/// Pharmacy management is handled through pharmacy mode toggle.
// ignore_for_file: unused_element

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/home/view/home_screen.dart';
import 'package:pharmacy_app/features/posts/view/create_post_screen.dart';
import 'package:pharmacy_app/features/posts/view/posts_feed_screen.dart';
import 'package:pharmacy_app/features/profile/view/profile_screen.dart';
import 'package:pharmacy_app/features/chat/view/screens/chats_list_screen.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:pharmacy_app/features/pharmacy_mode/view/screens/pharmacy_dashboard_screen.dart';
import 'package:pharmacy_app/features/pharmacy_mode/view/screens/pharmacy_orders_screen.dart';

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

    return [
      NavItem(
        label: isPharmacyMode ? 'Dashboard' : 'Home',
        icon: isPharmacyMode ? Icons.dashboard_outlined : Icons.medical_services_outlined,
        activeIcon: isPharmacyMode ? Icons.dashboard : Icons.medical_services,
        builder: (ref) => isPharmacyMode 
            ? const PharmacyDashboardScreen() 
            : const PatientHomeScreen(),
        route: isPharmacyMode ? '/pharmacy/dashboard' : '/home',
      ),
      NavItem(
        label: isPharmacyMode ? 'Chats' : 'Posts',
        icon: isPharmacyMode ? Icons.chat_bubble_outline : Icons.article_outlined,
        activeIcon: isPharmacyMode ? Icons.chat_bubble : Icons.article,
        builder: (ref) => isPharmacyMode 
            ? const ChatsListScreen() 
            : const PostsFeedScreen(),
        route: isPharmacyMode ? '/chats' : '/posts',
      ),
      // Center FAB - no regular nav item (index 2 is skipped for FAB)
      NavItem(
        label: isPharmacyMode ? 'Orders' : 'Chat',
        icon: isPharmacyMode ? Icons.inventory_2_outlined : Icons.chat_bubble_outline,
        activeIcon: isPharmacyMode ? Icons.inventory_2 : Icons.chat_bubble,
        builder: (ref) => isPharmacyMode 
            ? const PharmacyOrdersScreen() 
            : const ChatsListScreen(),
        route: isPharmacyMode ? '/pharmacy/orders' : '/chat',
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

