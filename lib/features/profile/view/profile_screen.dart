import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/profile/controller/profile_providers.dart';
import 'package:Elaaj/features/profile/view/edit_profile_screen.dart';
import 'package:Elaaj/features/profile/view/my_posts_screen.dart';
import 'package:Elaaj/features/profile/view/saved_posts_screen.dart';
import 'package:Elaaj/features/profile/view/widgets/profile_actions.dart';
import 'package:Elaaj/features/profile/view/widgets/profile_header.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/prescription/view/screens/my_prescriptions_screen.dart';

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
            // Personal Information
            SliverToBoxAdapter(
              child: ProfileSection(
                title: 'Personal Information',
                items: [
                  ProfileActionItem(
                    title: profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty
                        ? profile.dateOfBirth!
                        : 'Date of Birth (Not set)',
                    icon: Icons.cake_rounded,
                    iconColor: AppColors.accentRed,
                    trailingIcon: Icons.info_outline,
                  ),
                  ProfileActionItem(
                    title: profile.location != null && profile.location!.isNotEmpty
                        ? profile.location!
                        : 'Address (Not set)',
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.primaryGreen,
                    trailingIcon: Icons.info_outline,
                  ),
                ],
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
                        },
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
