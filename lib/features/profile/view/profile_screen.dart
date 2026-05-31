import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/profile/controller/profile_providers.dart';
import 'package:pharmacy_app/features/profile/view/edit_profile_screen.dart';
import 'package:pharmacy_app/features/profile/view/my_posts_screen.dart';
import 'package:pharmacy_app/features/profile/view/saved_posts_screen.dart';
import 'package:pharmacy_app/features/profile/view/widgets/profile_actions.dart';
import 'package:pharmacy_app/features/profile/view/widgets/profile_header.dart';
import 'package:pharmacy_app/features/profile/view/widgets/quick_stats.dart';
import 'package:pharmacy_app/features/auth/controller/auth_providers.dart';
import 'package:pharmacy_app/features/prescription/view/screens/my_prescriptions_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: profileAsync.when(
        data: (profile) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: ProfileHeader(
                profile: profile,
                onEdit: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const EditProfileScreen(),
                      transitionsBuilder: (_, animation, __, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            // Stats
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: QuickStats(profile: profile),
              ),
            ),
            // Activity section
            SliverToBoxAdapter(
              child: ProfileSection(
                title: 'Activity',
                items: [
                  ProfileActionItem(
                    title: 'My Posts',
                    icon: Icons.article_rounded,
                    iconColor: AppColors.primaryBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyPostsScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileActionItem(
                    title: 'Saved Posts',
                    icon: Icons.bookmark_rounded,
                    iconColor: AppColors.accentYellow,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedPostsScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileActionItem(
                    title: 'My Prescriptions',
                    icon: Icons.assignment_outlined,
                    iconColor: AppColors.primaryBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyPrescriptionsScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileActionItem(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.primaryGreen,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            // Settings section
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, _) {
                  final isDarkMode = ref.watch(darkModeProvider);
                  return ProfileSection(
                    title: 'Settings',
                    items: [
                      ProfileActionItem(
                        title: 'Dark Mode',
                        icon: isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: isDarkMode
                            ? AppColors.accentPurple
                            : AppColors.accentYellow,
                        isToggle: true,
                        toggleValue: isDarkMode,
                        onToggle: (value) {
                          ref.read(darkModeProvider.notifier).state = value;
                          // In production, use ThemeModeProvider or similar
                        },
                      ),
                      ProfileActionItem(
                        title: 'Language',
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        onTap: () {},
                      ),
                      ProfileActionItem(
                        title: 'Security',
                        icon: Icons.security_rounded,
                        iconColor: AppColors.primaryGreen,
                        onTap: () {},
                      ),
                      ProfileActionItem(
                        title: 'Help & Support',
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF0EA5E9),
                        onTap: () {},
                      ),
                      ProfileActionItem(
                        title: 'About Elaaj',
                        icon: Icons.info_outline_rounded,
                        iconColor: isDark
                            ? const Color(0xFF90CAF9)
                            : const Color(0xFF6366F1),
                        onTap: () {},
                      ),
                    ],
                  );
                },
              ),
            ),
            // Logout button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _LogoutDialog(),
                      );
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.accentRed),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.accentRed, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDark ? DarkColors.textHint : LightColors.textHint,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  color: isDark ? DarkColors.textHint : LightColors.textHint,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(profileProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      backgroundColor: isDark ? DarkColors.card : LightColors.card,
      title: Text(
        'Logout',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
        ),
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: TextStyle(
          color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(authProvider.notifier).logout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
