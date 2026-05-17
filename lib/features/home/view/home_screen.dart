// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/features/home/controller/home_providers.dart';
import 'package:pharmacy_app/features/home/view/widgets/home_header.dart';
import 'package:pharmacy_app/features/home/view/widgets/nearby_pharmacies_section.dart';
import 'package:pharmacy_app/features/home/view/widgets/quick_actions_section.dart';
import 'package:pharmacy_app/features/home/view/widgets/recent_posts_section.dart';
import 'package:pharmacy_app/features/home/view/widgets/smart_search_bar.dart';
import 'package:pharmacy_app/features/prescription/controller/prescription_providers.dart'
    hide nearbyPharmaciesProvider;
import 'package:pharmacy_app/features/pharmacy_mode/widgets/pharmacy_drawer.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() =>
      _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  // Removed GlobalKey<ScaffoldState> — it was never referenced.
  // Scaffold.of(context) in HomeHeader works without it.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const PharmacyDrawer(null),
      body: RefreshIndicator(
        // Extracted to a named method to avoid creating a new closure
        // on every build invocation.
        onRefresh: _handleRefresh,
        color: const Color(0xFF0EA5E9),
        child: CustomScrollView(
          cacheExtent: 250,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Header
            const SliverToBoxAdapter(child: HomeHeader()),
            // Search bar
            const SliverToBoxAdapter(child: SmartSearchBar()),
            // Removed SliverToBoxAdapter(child: SizedBox(height: 0))
            // — zero-height box is a no-op layout and wastes a sliver slot.
            // Nearby pharmacies
            const SliverToBoxAdapter(
                child: NearbyPharmaciesSection()),
            // Quick actions
            const SliverToBoxAdapter(child: QuickActionsSection()),
            // Recent posts
            const SliverToBoxAdapter(child: RecentPostsSection()),
            // Bottom padding for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final routingState =
              ref.watch(routingStateNotifierProvider);
          final isRequestPending =
              routingState?.isRequestPending ?? false;
          if (!isRequestPending) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () {
              context.push('/searching-pharmacies');
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.assignment, color: Colors.white),
          );
        },
      ),
    );
  }

  /// Extracted refresh handler — avoids allocating a new closure on each build.
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await Future.wait<void>([
        ref.read(nearbyPharmaciesProvider.notifier).refresh(),
        ref.read(recentPostsProvider.notifier).refresh(),
      ]);
    }
  }
}