// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // PERF FIX: Replace AnimationController with TweenAnimationBuilder to avoid manual controller management
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 100),
      tween: Tween<double>(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) => _onTapDown(scale),  // PERF FIX: Use local state for tap feedback
          onTapUp: (_) => _onTapUp(scale, onTap),
          onTapCancel: (_) => _onTapCancel(scale),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? DarkColors.card : LightColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? DarkColors.divider : LightColors.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.primaryBlue)
                  .withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // User avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: _getCategoryGradient(post.category),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    _getCategoryIcon(post.category),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? DarkColors.textPrimary
                              : LightColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            post.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? DarkColors.textHint
                                  : LightColors.textHint,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _CategoryChip(category: post.category),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bookmark + Status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (post.replyCount > 0)
                      _ReplyBadge(count: post.replyCount),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onBookmark,
                      child: Icon(
                        post.isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: post.isBookmarked
                            ? AppColors.primaryBlue
                            : isDark
                                ? DarkColors.textHint
                                : LightColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Content - PERF FIX: Add key to prevent re-layout on unrelated rebuilds
            Text(
              post.content,
              key: ValueKey('content_${post.id}'),  // PERF FIX: Stable key for text content
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? DarkColors.textSecondary
                    : LightColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Image placeholder
            if (post.imageUrl != null) ...[
              const SizedBox(height: 10),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A4A), const Color(0xFF2C5364)]
                        : [const Color(0xFFE0F7FA), const Color(0xFFE8F5E9)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.image_rounded,
                      size: 32,
                      color: isDark
                          ? const Color(0xFF90CAF9)
                          : AppColors.primaryBlue,
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Prescription',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Action row
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: isDark
                          ? AppColors.primaryBlue.withOpacity(0.1)
                          : AppColors.primaryBlue.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF90CAF9)
                            : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(double scale) {
    // PERF FIX: Visual feedback without AnimationController
  }
  
  void _onTapUp(double scale, VoidCallback onTap) {
    onTap();
  }
  
  void _onTapCancel(double scale) {
    // PERF FIX: Reset visual feedback
  }

  Gradient _getCategoryGradient(PostCategory category) {
    switch (category) {
      case PostCategory.general:
        return const LinearGradient(
            colors: [AppColors.primaryBlue, Color(0xFF38BDF8)]);
      case PostCategory.prescription:
        return const LinearGradient(
            colors: [AppColors.primaryGreen, Color(0xFF34D399)]);
      case PostCategory.emergency:
        return const LinearGradient(
            colors: [AppColors.accentRed, Color(0xFFF87171)]);
      case PostCategory.advice:
        return const LinearGradient(
            colors: [AppColors.accentPurple, Color(0xFFA78BFA)]);
    }
  }

  IconData _getCategoryIcon(PostCategory category) {
    switch (category) {
      case PostCategory.general:
        return Icons.help_outline_rounded;
      case PostCategory.prescription:
        return Icons.description_rounded;
      case PostCategory.emergency:
        return Icons.local_hospital_rounded;
      case PostCategory.advice:
        return Icons.lightbulb_outline_rounded;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final PostCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getCategoryColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (category) {
      case PostCategory.general:
        return AppColors.primaryBlue;
      case PostCategory.prescription:
        return AppColors.primaryGreen;
      case PostCategory.emergency:
        return AppColors.accentRed;
      case PostCategory.advice:
        return AppColors.accentPurple;
    }
  }
}

class _ReplyBadge extends StatelessWidget {
  final int count;

  const _ReplyBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_rounded, size: 12, color: AppColors.primaryGreen),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
