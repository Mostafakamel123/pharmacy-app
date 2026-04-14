// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/posts/controller/posts_providers.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final FocusNode _textFocus = FocusNode();

  @override
  void dispose() {
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createPostFormProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final charCount = formState.content.length;
    final hasContent = formState.content.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? DarkColors.background : LightColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hasContent ? 1.0 : 0.4,
            child: ElevatedButton(
              onPressed: hasContent && !formState.isSubmitting
                  ? () async {
                      HapticFeedback.lightImpact();
                      final success = await ref
                          .read(createPostFormProvider.notifier)
                          .submit();
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                disabledBackgroundColor:
                    AppColors.primaryBlue.withOpacity(0.3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: formState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Post',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Character count bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: hasContent ? 32 : 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '$charCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: charCount > 500
                            ? AppColors.accentRed
                            : isDark
                                ? DarkColors.textHint
                                : LightColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' / 500',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? DarkColors.textHint.withOpacity(0.5)
                            : LightColors.textHint.withOpacity(0.5),
                      ),
                    ),
                    if (charCount > 0) const SizedBox(width: 8),
                    if (charCount > 0)
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (charCount / 500).clamp(0, 1),
                          backgroundColor: isDark
                              ? DarkColors.surfaceVariant
                              : LightColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            charCount > 500
                                ? AppColors.accentRed
                                : AppColors.primaryBlue,
                          ),
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? DarkColors.divider
                                    : LightColors.divider,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'MK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mostafa Kamel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? DarkColors.textPrimary
                                      : LightColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Posting as Patient',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? DarkColors.textHint
                                      : LightColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Text area card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.card : LightColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: formState.error != null
                                ? AppColors.accentRed
                                : isDark
                                    ? DarkColors.divider
                                    : LightColors.divider,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          focusNode: _textFocus,
                          maxLines: null,
                          maxLength: 500,
                          autofocus: true,
                          onChanged: (value) => ref
                              .read(createPostFormProvider.notifier)
                              .updateContent(value),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'What medicine or health question do you have?',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? DarkColors.textHint.withOpacity(0.6)
                                  : LightColors.textHint.withOpacity(0.6),
                              fontSize: 16,
                              height: 1.6,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(18),
                            counterText: '',
                          ),
                        ),
                      ),
                      if (formState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 16, color: AppColors.accentRed),
                              const SizedBox(width: 6),
                              Text(
                                formState.error!,
                                style: const TextStyle(
                                  color: AppColors.accentRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Category selector
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? DarkColors.textPrimary
                              : LightColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose the type of your inquiry',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? DarkColors.textHint
                              : LightColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.card : LightColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: isDark
                                ? DarkColors.divider
                                : LightColors.divider,
                            width: 1,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PostCategory.values.map((cat) {
                            final isSelected = formState.category == cat;
                            return _ModernCategoryChip(
                              category: cat,
                              isSelected: isSelected,
                              onTap: () => ref
                                  .read(createPostFormProvider.notifier)
                                  .updateCategory(cat),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image upload
                      GestureDetector(
                        onTap: () => ref
                            .read(createPostFormProvider.notifier)
                            .toggleImage(),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? DarkColors.card
                                : LightColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: isDark
                                  ? DarkColors.divider
                                  : LightColors.divider,
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: formState.hasImage
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                                  const Color(0xFF1E3A4A),
                                                  const Color(0xFF2C5364)
                                                ]
                                              : [
                                                  const Color(0xFFE0F7FA),
                                                  const Color(0xFFE8F5E9)
                                                ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.xl),
                                      ),
                                      child: const Icon(
                                        Icons.image_rounded,
                                        size: 56,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.camera_alt_rounded,
                                                size: 14, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              'Tap to change',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.primaryBlue
                                                .withOpacity(0.12)
                                            : AppColors.primaryBlue
                                                .withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 28,
                                        color: isDark
                                            ? const Color(0xFF90CAF9)
                                            : AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Upload Prescription',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFF90CAF9)
                                            : AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Camera or Gallery',
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernCategoryChip extends StatelessWidget {
  final PostCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernCategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _getCategoryIcon(),
                key: ValueKey(isSelected),
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
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

  IconData _getCategoryIcon() {
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
