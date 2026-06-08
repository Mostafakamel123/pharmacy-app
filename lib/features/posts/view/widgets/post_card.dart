// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/posts/model/post_model.dart';
import 'package:Elaaj/features/profile/controller/profile_providers.dart';
import 'package:Elaaj/features/posts/controller/posts_providers.dart';
import 'package:Elaaj/features/posts/view/edit_post_screen.dart';

class PostCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabicText = _isArabic(post.content);
    
    // Get current user profile to determine ownership
    final profile = ref.watch(profileProvider).value;
    final isOwner = profile != null && profile.id == post.userId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // User avatar (Clean, Harmonious & Premium unified style)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
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
                              post.userName.isNotEmpty ? post.userName : 'Patient',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? DarkColors.textPrimary
                                    : LightColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              post.timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? DarkColors.textHint
                                    : LightColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Options or Bookmark Badge row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (post.replyCount > 0)
                            _ReplyBadge(count: post.replyCount),
                          const SizedBox(width: 4),
                          
                          // Bookmark Button (Only show if not the owner for clarity)
                          if (!isOwner && onBookmark != null)
                            GestureDetector(
                              onTap: onBookmark,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
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
                            ),
                          
                          // Owner Options Menu (Edit / Delete)
                          if (isOwner)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: isDark ? DarkColors.textHint : LightColors.textHint,
                              ),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditPostScreen(post: post),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  HapticFeedback.heavyImpact();
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.xl),
                                      ),
                                      backgroundColor: isDark ? DarkColors.card : LightColors.card,
                                      title: const Text('Delete Post', style: TextStyle(fontWeight: FontWeight.w700)),
                                      content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text('Cancel', style: TextStyle(color: isDark ? DarkColors.textSecondary : LightColors.textSecondary)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accentRed,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                          ),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final (success, error) = await ref
                                        .read(myPostsProvider.notifier)
                                        .deletePost(post.id);
                                    if (context.mounted) {
                                      if (success) {
                                        // Show success and pop immediately
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Post deleted successfully'),
                                            backgroundColor: AppColors.primaryGreen,
                                            duration: Duration(milliseconds: 800),
                                          ),
                                        );
                                        // Pop after brief delay to show snackbar
                                        await Future.delayed(const Duration(milliseconds: 1000));
                                        Navigator.of(context).pop();
                                      } else {
                                        // Show error message
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to delete post: ${error ?? "Unknown error"}'),
                                            backgroundColor: AppColors.accentRed,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryBlue),
                                      SizedBox(width: 8),
                                      Text('Edit Post'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRed),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: AppColors.accentRed)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Content
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      post.content,
                      textDirection: isArabicText ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: isArabicText ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? DarkColors.textSecondary
                            : LightColors.textSecondary,
                        height: 1.5,
                        fontFamily: isArabicText ? 'Cairo' : null,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Real High-Resolution Network Image
                  if (post.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isDark ? DarkColors.divider : LightColors.divider,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImageViewer(imageUrl: post.imageUrl!),
                              ),
                            );
                          },
                          child: Hero(
                            tag: post.imageUrl!,
                            child: Image.network(
                              post.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 40,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  
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
                            'View Details & Discussion',
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
          ),
        ),
      ),
    );
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
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

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            maxScale: 4.0,
            minScale: 0.5,
            child: Hero(
              tag: imageUrl,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
