// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';
import 'package:pharmacy_app/features/navigation/widgets/premium_nav_shell.dart';
import 'package:pharmacy_app/features/posts/view/post_details_screen.dart';
import 'package:pharmacy_app/features/posts/controller/posts_providers.dart';
import 'package:pharmacy_app/features/posts/view/widgets/post_card.dart'
    show FullScreenImageViewer;

/// Section on the Home Page showing a horizontally scrolling feed of Latest Posts.
/// Connects directly to the main postsFeedProvider to ensure 100% data correctness
/// and synchronization whenever posts are added, deleted, or replied to.
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
                    // Navigate to posts feed screen by switching bottom tab index to 2 (Posts)
                    ref.read(navigationIndexProvider.notifier).state = 2;
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
    final postsAsync = ref.watch(postsFeedProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const _EmptyState();
        }
        // Take only the first 5 posts for a clean, horizontally scrollable home list
        final recentPosts = posts.take(5).toList();
        return _PostList(posts: recentPosts);
      },
      loading: () => const _PostShimmerLoading(),
      error: (err, stack) => _ErrorState(
        onRetry: () => ref.read(postsFeedProvider.notifier).refresh(),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final List<PostModel> posts;

  const _PostList({required this.posts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: posts.map((post) => _PostCard(post: post)).toList(),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF1F2937);
    final borderCol = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);

    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

    // Get color for category
    Color categoryColor;
    Color categoryBg;
    switch (post.category) {
      case PostCategory.emergency:
        categoryColor = const Color(0xFFEF4444);
        categoryBg = const Color(0xFFFEE2E2);
        break;
      case PostCategory.advice:
        categoryColor = const Color(0xFF10B981);
        categoryBg = const Color(0xFFD1FAE5);
        break;
      case PostCategory.prescription:
        categoryColor = const Color(0xFF3B82F6);
        categoryBg = const Color(0xFFDBEAFE);
        break;
      case PostCategory.general:
      default:
        categoryColor = const Color(0xFF8B5CF6);
        categoryBg = const Color(0xFFEDE9FE);
        break;
    }

    if (isDark) {
      categoryBg = categoryColor.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(post: post),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(
            color: borderCol,
            width: 1,
          ),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Avatar + User details
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.userName.isNotEmpty ? post.userName : 'Patient',
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
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 10,
                                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      post.timeAgo,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    if (post.category != PostCategory.general) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 3,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        post.category.label,
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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Content text
                      Text(
                        post.content,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(imageUrl: post.imageUrl!),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (post.replyCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 9,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${post.replyCount} ردود',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'لا توجد ردود بعد',
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      fontFamily: 'Cairo',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: AppColors.primaryBlue,
        size: 14,
      ),
    );
  }
}

class _PostShimmerLoading extends StatelessWidget {
  const _PostShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 140, height: 14, color: shimmerColor),
                      const SizedBox(height: 8),
                      Container(width: double.infinity, height: 12, color: shimmerColor),
                      const SizedBox(height: 6),
                      Container(width: 180, height: 12, color: shimmerColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(width: 60, height: 10, color: shimmerColor),
                          const SizedBox(width: 12),
                          Container(width: 40, height: 10, color: shimmerColor),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            'No posts yet / لا توجد منشورات حالياً',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
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

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 32,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
            const SizedBox(height: 6),
            Text(
              'Failed to load posts / فشل تحميل المنشورات',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة / Retry', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}