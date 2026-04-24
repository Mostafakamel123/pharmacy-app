/// Unified navigation configuration for all users
/// 
/// The app now has a single navigation flow regardless of user type.
/// Pharmacy management is handled through pharmacy mode toggle.

import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/nav_colors.dart';
import 'package:pharmacy_app/features/home/view/home_screen.dart';
import 'package:pharmacy_app/features/posts/view/create_post_screen.dart';
import 'package:pharmacy_app/features/posts/view/posts_feed_screen.dart';
import 'package:pharmacy_app/features/profile/view/profile_screen.dart';
import 'package:pharmacy_app/features/chat/view/screens/chats_list_screen.dart';

/// Navigation item configuration
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget Function() builder;
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

  static const List<NavItem> items = [
    NavItem(
      label: 'Home',
      icon: Icons.medical_services_outlined,
      activeIcon: Icons.medical_services,
      builder: _buildHome,
      route: '/home',
    ),
    NavItem(
      label: 'Posts',
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
      builder: _buildPosts,
      route: '/posts',
    ),
    // Center FAB - no regular nav item (index 2 is skipped for FAB)
    NavItem(
      label: 'Chat',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      builder: _buildChat,
      route: '/chat',
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      builder: _buildProfile,
      route: '/profile',
    ),
  ];

  /// Center FAB configuration
  static const fabNavItem = NavItem(
    label: 'Add',
    icon: Icons.add,
    activeIcon: Icons.add,
    builder: _buildAdd,
    route: '/add',
  );

  // Screen builders
  static Widget _buildHome() => const HomeScreen();
  static Widget _buildPosts() => const PostsFeedScreen();
  static Widget _buildChat() => const ChatsListScreen();
  static Widget _buildProfile() => const ProfileScreen();
  static Widget _buildAdd() => const CreatePostScreen();

  /// Get screen by index (accounts for FAB at index 2)
  static Widget getScreenByIndex(int index) {
    if (index < 0 || index >= items.length) {
      return const SizedBox.shrink();
    }
    return items[index].builder();
  }

  /// Get route by index
  static String getRouteByIndex(int index) {
    if (index < 0 || index >= items.length) {
      return '/';
    }
    return items[index].route;
  }
}

