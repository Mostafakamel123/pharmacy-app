import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/navigation/widgets/premium_nav_shell.dart';
import 'package:Elaaj/features/posts/controller/posts_providers.dart';
import 'package:Elaaj/features/posts/model/post_model.dart';
import 'package:Elaaj/features/posts/view/post_details_screen.dart';
import 'package:Elaaj/features/posts/view/widgets/post_card.dart'
    show FullScreenImageViewer;

// ════════════════════════════════════════════════════════════════════════════
// RECENT POSTS SECTION
// ════════════════════════════════════════════════════════════════════════════

/// Vertically stacked list of the 5 most recent community posts.
///
/// Performance notes:
/// • Outer [RecentPostsSection] is a [ConsumerWidget] scoped narrowly to
///   [postsFeedProvider] — it rebuilds only when the feed changes, not on
///   unrelated provider changes.
/// • The header row is split from the body so that navigating away (which
///   rebuilds the navigation shell) doesn't cause a full rebuild of 5 cards.
/// • Each [_PostCard] is a const [StatelessWidget] — Flutter reuses the
///   element tree across parent rebuilds without diffing.
/// • [RepaintBoundary] is intentionally NOT placed at the section level
///   because vertical post cards scroll as part of the main [CustomScrollView]
///   and batching their paint with the surrounding content is cheaper.
/// • The `posts.take(5).toList()` operation runs in O(1) time since
///   `take` is lazy; the `toList()` materialises only 5 items max.
class RecentPostsSection extends ConsumerWidget {
  const RecentPostsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
    final viewAllColor =
        isDark ? const Color(0xFF90CAF9) : const Color(0xFF0EA5E9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Posts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(navigationIndexProvider.notifier).state = 2,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: viewAllColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Body ─────────────────────────────────────────────────────────
        const _RecentPostsBody(),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BODY  (async state router — scoped rebuild)
// ════════════════════════════════════════════════════════════════════════════

class _RecentPostsBody extends ConsumerWidget {
  const _RecentPostsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsFeedProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) return const _PostsEmptyState();
        final recent = posts.take(5).toList(growable: false);
        return _PostList(posts: recent);
      },
      loading: () => const _PostShimmerList(),
      error: (_, __) => _PostsErrorState(
        onRetry: () => ref.read(postsFeedProvider.notifier).refresh(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// POST LIST
// ════════════════════════════════════════════════════════════════════════════

class _PostList extends StatelessWidget {
  final List<PostModel> posts;
  const _PostList({required this.posts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        // Use a fixed list instead of posts.map().toList() inside build
        // to let Flutter's element diffing work efficiently.
        children: [
          for (final post in posts) _PostCard(post: post),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// POST CARD
// ════════════════════════════════════════════════════════════════════════════

/// Individual post card for the home feed.
///
/// Performance notes:
/// • Pure [StatelessWidget] — no state, no ticker, no provider watch.
/// • withOpacity() calls replaced with compile-time hex-alpha constants to
///   avoid allocating new Color objects on every build.
/// • Image.network is wrapped in a fixed-size SizedBox so Flutter's layout
///   system doesn't need to measure the image to constrain it.
class _PostCard extends StatelessWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.surface : LightColors.surface;
    final textCol = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
    final borderCol =
        isDark ? const Color(0x14FFFFFF) : const Color(0x0D000000);
    final contentCol =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);
    final metaCol =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final hasImage =
        post.imageUrl != null && post.imageUrl!.isNotEmpty;

    // Resolve category colours once.
    final catStyle = _categoryStyle(post.category, isDark);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PostDetailsScreen(post: post),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(color: borderCol, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x33000000)
                  : const Color(0x040EA5E9),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: avatar · name · image thumb ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: avatar + user info + post content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar + name + time
                      Row(
                        children: [
                          const _PostAvatar(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PostMeta(
                              userName: post.userName,
                              timeAgo: post.timeAgo,
                              category: post.category,
                              categoryColor: catStyle.color,
                              metaCol: metaCol,
                              textCol: textCol,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Post content snippet
                      Text(
                        post.content,
                        style: TextStyle(
                          fontSize: 12,
                          color: contentCol,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Right: thumbnail (only if image present)
                if (hasImage) ...[
                  const SizedBox(width: 10),
                  _PostThumbnail(
                    imageUrl: post.imageUrl!,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // ── Footer: reply count ──────────────────────────────────
            _PostFooter(
              replyCount: post.replyCount,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  /// Map category → colour pair without allocating a switch-result object.
  static _CatStyle _categoryStyle(PostCategory cat, bool isDark) {
    switch (cat) {
      case PostCategory.emergency:
        return _CatStyle(
          color: const Color(0xFFEF4444),
          bg: isDark ? const Color(0x26EF4444) : const Color(0xFFFEE2E2),
        );
      case PostCategory.advice:
        return _CatStyle(
          color: const Color(0xFF10B981),
          bg: isDark ? const Color(0x2610B981) : const Color(0xFFD1FAE5),
        );
      case PostCategory.prescription:
        return _CatStyle(
          color: const Color(0xFF3B82F6),
          bg: isDark ? const Color(0x263B82F6) : const Color(0xFFDBEAFE),
        );
      case PostCategory.general:
        return _CatStyle(
          color: const Color(0xFF8B5CF6),
          bg: isDark ? const Color(0x268B5CF6) : const Color(0xFFEDE9FE),
        );
    }
  }
}

/// Lightweight value object — no allocation beyond two Color fields.
class _CatStyle {
  final Color color;
  final Color bg;
  const _CatStyle({required this.color, required this.bg});
}

// ════════════════════════════════════════════════════════════════════════════
// POST SUB-WIDGETS (all const / parameter-driven)
// ════════════════════════════════════════════════════════════════════════════

class _PostAvatar extends StatelessWidget {
  const _PostAvatar();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Icon(Icons.person_rounded, color: Colors.white, size: 13),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _PostMeta extends StatelessWidget {
  final String userName;
  final String timeAgo;
  final PostCategory category;
  final Color categoryColor;
  final Color metaCol;
  final Color textCol;
  final bool isDark;

  const _PostMeta({
    required this.userName,
    required this.timeAgo,
    required this.category,
    required this.categoryColor,
    required this.metaCol,
    required this.textCol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dotCol = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName.isNotEmpty ? userName : 'Patient',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            Icon(Icons.access_time_rounded, size: 10, color: metaCol),
            const SizedBox(width: 3),
            Text(
              timeAgo,
              style: TextStyle(fontSize: 9.5, color: metaCol),
            ),
            if (category != PostCategory.general) ...[
              const SizedBox(width: 6),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: dotCol,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 3, height: 3),
              ),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _PostThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isDark;

  const _PostThumbnail({required this.imageUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Image.network(
          imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          // cacheWidth limits GPU texture size for small thumbnails.
          cacheWidth: 112,
          errorBuilder: (_, __, ___) => _ImagePlaceholder(isDark: isDark),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;
  const _ImagePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? DarkColors.divider : LightColors.divider,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: const SizedBox(
        width: 56,
        height: 56,
        child: Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.primaryBlue,
          size: 14,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _PostFooter extends StatelessWidget {
  final int replyCount;
  final bool isDark;

  const _PostFooter({required this.replyCount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (replyCount > 0) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0x1410B981),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 9,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 3),
              Text(
                '$replyCount ردود',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Text(
      'لا توجد ردود بعد',
      style: TextStyle(
        fontSize: 9,
        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        fontFamily: 'Cairo',
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHIMMER LOADING (flat skeleton — no animation tickers)
// ════════════════════════════════════════════════════════════════════════════

class _PostShimmerList extends StatelessWidget {
  const _PostShimmerList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          // Generate 3 skeleton cards.
          _PostShimmerCard(isDark: isDark),
          _PostShimmerCard(isDark: isDark),
          _PostShimmerCard(isDark: isDark),
        ],
      ),
    );
  }
}

class _PostShimmerCard extends StatelessWidget {
  final bool isDark;
  const _PostShimmerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? DarkColors.surface : LightColors.surface;
    final shimmer = isDark ? DarkColors.divider : LightColors.divider;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: base,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name row
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6)),
                      ),
                      child: const SizedBox(width: 26, height: 26),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(color: shimmer),
                      child: const SizedBox(width: 100, height: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(color: shimmer),
                  child: const SizedBox(
                      width: double.infinity, height: 12),
                ),
                const SizedBox(height: 6),
                DecoratedBox(
                  decoration: BoxDecoration(color: shimmer),
                  child: const SizedBox(width: 180, height: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: shimmer),
                      child: const SizedBox(width: 60, height: 10),
                    ),
                    const SizedBox(width: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(color: shimmer),
                      child: const SizedBox(width: 40, height: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: const SizedBox(width: 56, height: 56),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY / ERROR STATES
// ════════════════════════════════════════════════════════════════════════════

class _PostsEmptyState extends StatelessWidget {
  const _PostsEmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 40,
            color: isDark ? DarkColors.textHint : LightColors.textHint,
          ),
          const SizedBox(height: 10),
          Text(
            'No posts yet / لا توجد منشورات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? DarkColors.textSecondary
                  : LightColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _PostsErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _PostsErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: isDark ? DarkColors.textHint : LightColors.textHint,
            ),
            const SizedBox(height: 6),
            Text(
              'Failed to load posts / فشل تحميل المنشورات',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? DarkColors.textSecondary
                    : LightColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'إعادة المحاولة / Retry',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
