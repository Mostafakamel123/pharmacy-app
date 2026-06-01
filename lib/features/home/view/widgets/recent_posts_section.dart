// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/home/controller/home_providers.dart';
import 'package:pharmacy_app/features/home/model/home_post_model.dart';
import 'package:pharmacy_app/features/navigation/widgets/premium_nav_shell.dart';
import 'package:pharmacy_app/features/posts/view/post_details_screen.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';
import 'package:pharmacy_app/features/posts/view/widgets/post_card.dart';

class RecentPostsSection extends ConsumerWidget {
  const RecentPostsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to posts feed screen by switching bottom tab
                    ref.read(navigationIndexProvider.notifier).state = 1;
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF90CAF9)
                          : const Color(0xFF0EA5E9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _RecentPostsBody(),
        ],
      ),
    );
  }
}

class _RecentPostsBody extends ConsumerWidget {
  const _RecentPostsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(recentPostsProvider);

    return postsAsync.when(
      data: (posts) => _PostList(posts: posts),
      loading: () => const _PostShimmerLoading(),
      error: (_, __) => _ErrorState(
        onRetry: () =>
            ref.read(recentPostsProvider.notifier).refresh(),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final List<HomePostModel> posts;

  const _PostList({required this.posts});

  @override
  Widget build(BuildContext context) {
    // Replaced ListView.separated(shrinkWrap: true, NeverScrollableScrollPhysics)
    // with a plain Column. A non-scrollable ListView still creates viewport,
    // scroll physics, and lazy-loading machinery — all unnecessary overhead
    // for a static, non-scrollable list.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          for (int i = 0; i < posts.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _PostCard(post: posts[i]),
          ],
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final HomePostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Navigate to post details screen directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(
              post: PostModel(
                id: post.id,
                userId: 'unknown',
                userName: 'User',
                content: post.question,
                category: PostCategory.general,
                imageUrl: post.attachmentUrl,
                replyCount: post.replyCount,
                status: post.hasResponse ? PostStatus.replied : PostStatus.open,
                createdAt: post.createdAt,
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          border: Border.all(
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x33000000) // black @ 0.2
                  : const Color(0x0A0EA5E9), // blue @ 0.04
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Post Image (or placeholder) at the front/left
            GestureDetector(
              onTap: post.attachmentUrl != null && post.attachmentUrl!.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(imageUrl: post.attachmentUrl!),
                        ),
                      );
                    }
                  : null,
              child: Hero(
                tag: post.attachmentUrl ?? 'placeholder_${post.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: post.attachmentUrl != null && post.attachmentUrl!.isNotEmpty
                      ? Image.network(
                          post.attachmentUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 64,
                              height: 64,
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0EA5E9),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
                        )
                      : _buildPlaceholder(isDark),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Post Content (Question) on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${post.timeAgo} ago',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      if (post.replyCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 11,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${post.replyCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
              : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: Color(0xFF0EA5E9),
        size: 24,
      ),
    );
  }
}

class _PostShimmerLoading extends StatelessWidget {
  const _PostShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ShimmerPostCard(
              isDark: isDark,
              shimmerColor: shimmerColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Extracted shimmer card to avoid duplicating decoration logic per index.
class _ShimmerPostCard extends StatelessWidget {
  final bool isDark;
  final Color shimmerColor;

  const _ShimmerPostCard({
    required this.isDark,
    required this.shimmerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: 100, height: 14, color: shimmerColor),
                  const SizedBox(height: 6),
                  Container(
                      width: 60, height: 12, color: shimmerColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
              width: double.infinity, height: 16, color: shimmerColor),
          const SizedBox(height: 6),
          Container(width: 180, height: 14, color: shimmerColor),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40,
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF)),
            const SizedBox(height: 8),
            Text(
              'Failed to load posts',
              style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}