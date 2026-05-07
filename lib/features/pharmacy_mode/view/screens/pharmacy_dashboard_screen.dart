// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:pharmacy_app/features/pharmacy_mode/view/widgets/pharmacy_stats_card.dart';
import 'package:pharmacy_app/features/pharmacy_mode/view/widgets/pharmacy_quick_actions.dart';
import 'package:pharmacy_app/features/pharmacy_mode/view/widgets/pharmacy_recent_activity.dart';
import 'package:pharmacy_app/features/pharmacy_mode/widgets/pharmacy_drawer.dart';

/// Pharmacy Dashboard Screen
/// 
/// Displays pharmacy stats, quick actions, and recent activity
/// when user is in Pharmacy Mode.
/// 
/// Performance Optimizations:
/// - Uses ConsumerWidget with selective provider watchers
/// - Extracts header into separate widget with const constructor
/// - Uses SliverList for efficient scrolling
/// - Minimizes rebuilds by isolating state-dependent widgets
/// - Caches theme values to avoid repeated lookups
/// - Implements proper empty state handling
class PharmacyDashboardScreen extends ConsumerWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selective watch: only rebuild when currentPharmacy changes
    final currentPharmacy = ref.watch(currentPharmacyProvider);

    // If no pharmacy selected, show empty state
    if (currentPharmacy == null) {
      return const _EmptyDashboardState();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: PharmacyDrawer(currentPharmacy),
      body: CustomScrollView(
        slivers: [
          // Header with pharmacy info
          SliverToBoxAdapter(
            child: _DashboardHeader(pharmacyName: currentPharmacy.name),
          ),
          // Stats Cards
          const SliverToBoxAdapter(
            child: PharmacyStatsCard(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),
          // Quick Actions
          const SliverToBoxAdapter(
            child: PharmacyQuickActions(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),
          // Recent Activity
          const SliverToBoxAdapter(
            child: PharmacyRecentActivity(),
          ),
          // Bottom padding for nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget when no pharmacy is selected
class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final textHint = isDark ? DarkColors.textHint : LightColors.textHint;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_outlined,
                    size: 80,
                    color: textHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'No Pharmacy Selected',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Select a pharmacy from the drawer to view dashboard and manage your pharmacy operations',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                ElevatedButton.icon(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.storefront),
                  label: const Text('Select Pharmacy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard header widget
/// Only rebuilds when pharmacyName changes
class _DashboardHeader extends StatelessWidget {
  final String pharmacyName;

  const _DashboardHeader({required this.pharmacyName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(AppRadius.xxl),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Menu button to open drawer
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pharmacy Dashboard',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pharmacyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notifications icon
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.accentRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
