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
/// - Uses selective provider watchers to minimize rebuilds
/// - Extracts static header to const widget where possible
/// - Minimizes Theme.of() calls by caching values
/// - Uses SliverList for efficient scrolling
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

    // Cache theme brightness to avoid repeated lookups
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      drawer: PharmacyDrawer(currentPharmacy),
      body: CustomScrollView(
        slivers: [
          // Header - cached pharmacy name to avoid redundant reads
          SliverToBoxAdapter(
            child: _DashboardHeader(pharmacyName: currentPharmacy.name),
          ),
          // Stats Cards - independent widget, won't rebuild on header changes
          const SliverToBoxAdapter(
            child: PharmacyStatsCard(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),
          // Quick Actions - independent widget
          const SliverToBoxAdapter(
            child: PharmacyQuickActions(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),
          // Recent Activity - independent widget
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

/// Extracted empty state widget with const constructor
class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final textHint = isDark ? DarkColors.textHint : LightColors.textHint;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 80,
              color: textHint,
            ),
            const SizedBox(height: 24),
            Text(
              'No Pharmacy Selected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a pharmacy from the drawer to view dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.storefront),
              label: const Text('Select Pharmacy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracted header widget to isolate rebuild scope
/// Only rebuilds when pharmacyName changes
class _DashboardHeader extends StatelessWidget {
  final String pharmacyName;

  const _DashboardHeader({required this.pharmacyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pharmacy Dashboard',
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
            ],
          ),
        ],
      ),
    );
  }
}
