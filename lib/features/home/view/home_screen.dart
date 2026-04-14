import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/home/controller/home_providers.dart';
import 'package:pharmacy_app/features/home/view/widgets/home_header.dart';
import 'package:pharmacy_app/features/home/view/widgets/nearby_pharmacies_section.dart';
import 'package:pharmacy_app/features/home/view/widgets/quick_actions_section.dart';
import 'package:pharmacy_app/features/home/view/widgets/recent_posts_section.dart';
import 'package:pharmacy_app/features/home/view/widgets/smart_search_bar.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(nearbyPharmaciesProvider.notifier).refresh(),
            ref.read(recentPostsProvider.notifier).refresh(),
          ]);
        },
        color: const Color(0xFF0EA5E9),
        child: CustomScrollView(
          cacheExtent: 500,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Header
            const SliverToBoxAdapter(child: RepaintBoundary(child: HomeHeader())),
            // Search bar with proper spacing
            const SliverToBoxAdapter(child: SmartSearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 0)),
            // Nearby pharmacies
            const SliverToBoxAdapter(child: NearbyPharmaciesSection()),
            // Quick actions
           
            const SliverToBoxAdapter(child: QuickActionsSection()),
            // CTA banner
            // const SliverToBoxAdapter(child: CTABanner()),
            // Recent posts
            const SliverToBoxAdapter(child: RecentPostsSection()),
            // Bottom padding for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
