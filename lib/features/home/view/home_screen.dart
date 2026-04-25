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
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const PharmacyDrawer(null),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait<void>([
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
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final routingState = ref.watch(routingStateNotifierProvider);
          final isRequestPending = routingState?.isRequestPending ?? false;
          print('🎯 DEBUG HomeScreen: routingState=${routingState?.id}, isRequestPending=$isRequestPending');
          if (!isRequestPending) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () {
              // Navigate back to the prescription screen
              context.push('/searching-pharmacies');
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.assignment, color: Colors.white),
          );
        },
      ),
    );
  }
}
