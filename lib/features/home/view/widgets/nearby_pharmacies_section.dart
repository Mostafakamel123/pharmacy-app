import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/config/env_config.dart';
import 'package:Elaaj/core/models/pharmacy_model.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/home/controller/home_providers.dart';
import 'package:Elaaj/features/pharmacies/view/nearby_pharmacies_screen.dart';
import 'package:Elaaj/features/pharmacies/view/pharmacy_details_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// NEARBY PHARMACIES SECTION
// ════════════════════════════════════════════════════════════════════════════

/// Horizontally scrolling list of pharmacies filtered by the search query.
///
/// Performance notes:
/// • The outer [NearbyPharmaciesSection] is a plain [StatelessWidget] — it
///   never watches any provider, so it is allocated once and reused.
/// • Provider watching is scoped to [_NearbyPharmaciesBody], the minimal
///   subtree that needs to rebuild on data changes.
/// • [RepaintBoundary] is NOT placed here because this section is static
///   once data arrives. Overusing RepaintBoundary adds GPU layer overhead.
/// • The horizontal [ListView.separated] has:
///   - A fixed-height [SizedBox] parent (138 px) so Flutter never measures
///     intrinsic height — avoiding an O(N) layout pass.
///   - `cacheExtent: 350` — keeps ~2 cards pre-rendered off each side.
///   - `addAutomaticKeepAlives: false` — stateless cards don't need
///     KeepAlive wrappers.
///   - `addRepaintBoundaries: false` — each simple card does not warrant
///     its own compositing layer; batching draws is cheaper.
class NearbyPharmaciesSection extends ConsumerWidget {
  const NearbyPharmaciesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    // Watch the query so the title updates reactively.
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;

    // When searching, show how many results came back.
    final resultsAsync = ref.watch(filteredNearbyPharmaciesProvider);
    final resultCount = resultsAsync.valueOrNull?.length;

    final title = isSearching
        ? (resultCount != null
            ? 'Search Results ($resultCount)'
            : 'Searching...')
        : 'Nearby Pharmacies';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Animated title transition between modes
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (!isSearching)
                TextButton(
                  onPressed: () => _navigateToAll(context),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // ── Body: async state switching ──────────────────────────────────
        const _NearbyPharmaciesBody(),
      ],
    );
  }

  static void _navigateToAll(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const NearbyPharmaciesScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _NearbyPharmaciesBody extends ConsumerWidget {
  const _NearbyPharmaciesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsync = ref.watch(filteredNearbyPharmaciesProvider);

    return pharmaciesAsync.when(
      data: (pharmacies) => pharmacies.isEmpty
          ? const _EmptyPharmacyState()
          : _PharmacyList(pharmacies: pharmacies),
      loading: () => const _PharmacyShimmerList(),
      error: (_, __) => _PharmacyErrorState(
        onRetry: () => ref.read(nearbyPharmaciesProvider.notifier).refresh(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PHARMACY LIST
// ════════════════════════════════════════════════════════════════════════════

class _PharmacyList extends StatelessWidget {
  final List<PharmacyModel> pharmacies;
  const _PharmacyList({required this.pharmacies});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pharmacies.length,
        cacheExtent: 350,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) =>
            _PharmacyCard(pharmacy: pharmacies[index]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PHARMACY CARD
// ════════════════════════════════════════════════════════════════════════════

class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  const _PharmacyCard({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? DarkColors.surface : LightColors.surface;
    final borderColor = isDark ? DarkColors.divider : LightColors.divider;
    final nameColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
    final metaColor =
        isDark ? const Color(0xFF90CAF9) : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PharmacyDetailsScreen(pharmacy: pharmacy),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 170,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x33000000)
                    : const Color(0x0F0EA5E9),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pharmacy image ───────────────────────────────────────
                _PharmacyImage(imageUrl: pharmacy.imageUrl, isDark: isDark),
                const SizedBox(height: 6),
                // ── Name ─────────────────────────────────────────────────
                Text(
                  pharmacy.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: nameColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // ── Distance & Rating ────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.directions_walk_rounded,
                        size: 12, color: metaColor),
                    const SizedBox(width: 3),
                    Text(
                      '${pharmacy.distance.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 11, color: metaColor),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded,
                        size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      pharmacy.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // ── Status badges ────────────────────────────────────────
                Row(
                  children: [
                    _StatusBadge(isOpen: pharmacy.isOpen),
                    if (pharmacy.hasDelivery) ...[
                      const SizedBox(width: 6),
                      const _DeliveryBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

/// Top image area of a pharmacy card.
/// Shows [imageUrl] as a network image when available, otherwise falls back
/// to the branded gradient + location icon placeholder.
class _PharmacyImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;

  const _PharmacyImage({required this.imageUrl, required this.isDark});

  String? _resolvedUrl() {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http')) return imageUrl;
    // Relative path from the API — prepend the base URL
    return '${EnvConfig.apiBaseUrl}$imageUrl';
  }

  Widget _fallback() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1E3A4A), Color(0xFF2C5364)]
                : const [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: SizedBox(
          height: 42,
          width: double.infinity,
          child: Center(
            child: Icon(
              Icons.local_pharmacy_rounded,
              color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue,
              size: 22,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl();
    if (url == null) return _fallback();

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: SizedBox(
        height: 42,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          // Show a shimmer-like placeholder while loading
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A4A)
                    : const Color(0xFFE0F7FA),
              ),
              child: const SizedBox.expand(),
            );
          },
          // Fall back to the branded placeholder on error
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isOpen
            ? const Color(0x2610B981)
            : const Color(0x26EF4444),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          isOpen ? 'Open' : 'Closed',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isOpen
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }
}

class _DeliveryBadge extends StatelessWidget {
  const _DeliveryBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0x260EA5E9),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delivery_dining_rounded,
                size: 12, color: Color(0xFF0EA5E9)),
            SizedBox(width: 3),
            Text(
              'Delivery',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHIMMER LOADING (flat, no per-widget AnimationController)
// ════════════════════════════════════════════════════════════════════════════

/// A flat, unanimated skeleton placeholder for the pharmacy list.
///
/// Deliberately static (no animation ticker) to avoid creating AnimationController
/// objects during a loading state that typically lasts < 1 second.
/// A gentle pulse could be added later with a single shared ticker at the
/// screen level if desired.
class _PharmacyShimmerList extends StatelessWidget {
  const _PharmacyShimmerList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => _PharmacyShimmerCard(isDark: isDark),
      ),
    );
  }
}

class _PharmacyShimmerCard extends StatelessWidget {
  final bool isDark;
  const _PharmacyShimmerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? DarkColors.surface : LightColors.surface;
    final shimmer = isDark ? DarkColors.divider : LightColors.divider;

    return SizedBox(
      width: 170,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: base,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: const SizedBox(height: 42, width: double.infinity),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(color: shimmer),
                child: const SizedBox(height: 12, width: 100),
              ),
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: BoxDecoration(color: shimmer),
                child: const SizedBox(height: 11, width: 70),
              ),
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: BoxDecoration(color: shimmer),
                child: const SizedBox(height: 11, width: 60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY / ERROR STATES
// ════════════════════════════════════════════════════════════════════════════

class _EmptyPharmacyState extends StatelessWidget {
  const _EmptyPharmacyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'No pharmacies found nearby',
          style: TextStyle(
            fontSize: 13,
            color:
                isDark ? DarkColors.textSecondary : LightColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PharmacyErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _PharmacyErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 138,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: isDark ? DarkColors.textHint : LightColors.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load pharmacies',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? DarkColors.textSecondary
                    : LightColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
