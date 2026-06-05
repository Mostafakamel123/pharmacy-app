// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Elaaj/core/routing/app_routes.dart';
import 'package:Elaaj/features/home/controller/home_providers.dart';
import 'package:Elaaj/features/home/view/widgets/home_header.dart';
import 'package:Elaaj/features/home/view/widgets/nearby_pharmacies_section.dart';
import 'package:Elaaj/features/home/view/widgets/quick_actions_section.dart';
import 'package:Elaaj/features/home/view/widgets/recent_posts_section.dart';
import 'package:Elaaj/features/home/view/widgets/smart_search_bar.dart';
import 'package:Elaaj/features/pharmacy_mode/widgets/pharmacy_drawer.dart';
import 'package:Elaaj/features/posts/controller/posts_providers.dart';
import 'package:Elaaj/features/prescription/controller/prescription_providers.dart'
    hide nearbyPharmaciesProvider;
import 'package:Elaaj/features/profile/controller/profile_providers.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  // ── The scroll controller is created once and never recreated. ──────────
  // Passing it to RefreshIndicator.scrollController ensures the indicator
  // can read the scroll position without constructing a new ScrollController
  // on every build call.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const PharmacyDrawer(null),
      // ── Full-page scroll: HomeHeader scrolls with content ──────────────
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF0EA5E9),
        strokeWidth: 2.5,
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 400,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: const [
            // ── Header scrolls away with content ──────────────────────
            SliverToBoxAdapter(child: HomeHeader()),

            // ── Search bar stays pinned when header scrolls off ────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedSearchDelegate(),
            ),

            // ── Nearby pharmacies horizontal list ──────────────────────
            SliverToBoxAdapter(child: NearbyPharmaciesSection()),

            // ── Quick action pills ─────────────────────────────────────
            SliverToBoxAdapter(child: QuickActionsSection()),

            // ── Recent posts vertical list ─────────────────────────────
            SliverToBoxAdapter(child: RecentPostsSection()),

            // ── Bottom padding for the floating nav bar ────────────────
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      // ── FAB: scoped Consumer so only this subtree rebuilds on routing ──
      floatingActionButton: _PrescriptionFab(),
    );
  }

  /// Extracted refresh handler — avoids allocating a new closure on each
  /// build invocation. Uses Future.wait so all three providers refresh in
  /// parallel rather than sequentially.
  Future<void> _handleRefresh() async {
    await Future.wait<void>([
      ref.read(profileProvider.notifier).refresh(),
      ref.read(nearbyPharmaciesProvider.notifier).refresh(),
      ref.read(postsFeedProvider.notifier).refresh(),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PINNED SEARCH DELEGATE
// ════════════════════════════════════════════════════════════════════════════

/// Zero-overhead SliverPersistentHeaderDelegate.
///
/// • Fixed min/max extent → Flutter skips the shrink animation entirely,
///   so `build()` is never called for size changes — only for scroll overlap.
/// • When pinned & overlapping, we swap from transparent to a solid
///   scaffoldBackgroundColor using a simple conditional — absolutely no
///   BackdropFilter / saveLayer() call on the GPU.
/// • `shouldRebuild` returns false because the delegate carries no mutable
///   state — the child widget itself handles state changes internally.
class _PinnedSearchDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedSearchDelegate();

  /// Total height = search bar height (48) + top padding (8) + bottom (12).
  static const double _kHeight = 68.0;

  @override
  double get minExtent => _kHeight;

  @override
  double get maxExtent => _kHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // When pinned on top of content, use a solid opaque background.
    // This avoids any saveLayer() / compositing cost while still
    // providing a visual separation from content scrolling underneath.
    final Color bg = overlapsContent
        ? Theme.of(context).scaffoldBackgroundColor
        : Colors.transparent;

    return ColoredBox(
      color: bg,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
        child: SmartSearchBar(),
      ),
    );
  }

  // Delegate is stateless — no rebuild needed when the sliver is re-laid-out.
  @override
  bool shouldRebuild(covariant _PinnedSearchDelegate oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════════════════
// PRESCRIPTION FAB
// ════════════════════════════════════════════════════════════════════════════

/// Scoped Consumer widget so only this tiny subtree rebuilds when
/// `routingStateNotifierProvider` changes. The parent screen is untouched.
class _PrescriptionFab extends ConsumerWidget {
  const _PrescriptionFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // .select() means we only rebuild when `isRequestPending` flips,
    // not on every RoutingStateModel field change.
    final isRequestPending = ref.watch(
      routingStateNotifierProvider.select(
        (state) => state?.isRequestPending ?? false,
      ),
    );

    if (!isRequestPending) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: () => context.push(AppRoutes.searchingPharmacies),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.assignment, color: Colors.white),
    );
  }
}
