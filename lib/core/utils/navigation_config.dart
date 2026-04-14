import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/nav_colors.dart';
import 'package:pharmacy_app/features/home/view/home_screen.dart';
import 'package:pharmacy_app/features/posts/view/posts_feed_screen.dart';

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

/// Navigation configuration for Patient role
class PatientNavItems {
  PatientNavItems._();

  static const List<NavItem> items = [
    NavItem(
      label: 'Home',
      icon: Icons.medical_services_outlined,
      activeIcon: Icons.medical_services,
      builder: _placeholderHome,
      route: '/patient/home',
    ),
    NavItem(
      label: 'Posts',
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
      builder: _placeholderPosts,
      route: '/patient/posts',
    ),
    // Center FAB - no regular nav item
    NavItem(
      label: 'Chat',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      builder: _placeholderChat,
      route: '/patient/chat',
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      builder: _placeholderProfile,
      route: '/patient/profile',
    ),
  ];

  // Center FAB configuration
  static const fabNavItem = NavItem(
    label: 'Add',
    icon: Icons.add,
    activeIcon: Icons.add,
    builder: _placeholderAdd,
    route: '/patient/add',
  );

  // Placeholder screens - replace with actual screens
  static Widget _placeholderHome() => const PatientHomeScreen();

  static Widget _placeholderPosts() => const PostsFeedScreen();

  static Widget _placeholderChat() => _PlaceholderScreen(
        title: 'Messages',
        icon: Icons.chat_bubble,
        gradient: NavColors.primaryGradient,
      );

  static Widget _placeholderProfile() => _PlaceholderScreen(
        title: 'Profile',
        icon: Icons.person,
        gradient: NavColors.primaryGradient,
      );

  static Widget _placeholderAdd() => _PlaceholderScreen(
        title: 'Create Post',
        icon: Icons.add,
        gradient: NavColors.fabGradient,
      );
}

/// Navigation configuration for Pharmacy role
class PharmacyNavItems {
  PharmacyNavItems._();

  static const List<NavItem> items = [
    NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      builder: _placeholderHome,
      route: '/pharmacy/home',
    ),
    NavItem(
      label: 'Requests',
      icon: Icons.inbox_outlined,
      activeIcon: Icons.inbox,
      builder: _placeholderRequests,
      route: '/pharmacy/requests',
    ),
    NavItem(
      label: 'Community',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      builder: _placeholderCommunity,
      route: '/pharmacy/community',
    ),
    NavItem(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      builder: _placeholderNotifications,
      route: '/pharmacy/notifications',
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
      builder: _placeholderProfile,
      route: '/pharmacy/profile',
    ),
  ];

  // Placeholder screens - replace with actual screens
  static Widget _placeholderHome() => _PlaceholderScreen(
        title: 'Incoming Posts',
        icon: Icons.home,
        gradient: NavColors.primaryGradient,
      );

  static Widget _placeholderRequests() => _PlaceholderScreen(
        title: 'Requests to Respond',
        icon: Icons.inbox,
        gradient: NavColors.primaryGradient,
      );

  static Widget _placeholderCommunity() => _PlaceholderScreen(
        title: 'Pharmacists Chat',
        icon: Icons.groups,
        gradient: NavColors.primaryGradient,
      );

  static Widget _placeholderNotifications() => _PlaceholderScreen(
        title: 'Notifications',
        icon: Icons.notifications,
        gradient: NavColors.primaryGradient,
      );

  static Widget _placeholderProfile() => _PlaceholderScreen(
        title: 'Pharmacy Profile',
        icon: Icons.business,
        gradient: NavColors.primaryGradient,
      );
}

/// Generic placeholder screen (replace with actual screens)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Replace with actual screen',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
