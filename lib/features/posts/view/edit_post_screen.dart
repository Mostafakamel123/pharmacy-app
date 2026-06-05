// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/posts/controller/posts_providers.dart';
import 'package:Elaaj/features/posts/model/post_model.dart';
import 'package:Elaaj/features/profile/controller/profile_providers.dart';
import 'package:image_picker/image_picker.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  final FocusNode _textFocus = FocusNode();
  late TextEditingController _textController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _textFocus.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        ref.read(editPostFormProvider(widget.post).notifier).setPickedImage(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? DarkColors.card : LightColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? DarkColors.divider : LightColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryBlue),
              title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
              title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(editPostFormProvider(widget.post));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);
    final charCount = formState.content.length;
    final hasContent = formState.content.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? DarkColors.background : LightColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
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
                          .read(editPostFormProvider(widget.post).notifier)
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
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
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
                        Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '$charCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: charCount > 500
                            ? AppColors.accentRed
                            : isDark
                                ? DarkColors.textHint
                                : LightColors.textHint,
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
                          profileAsync.maybeWhen(
                            data: (profile) => Container(
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
                              child: Center(
                                child: Text(
                                  profile.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            orElse: () => Container(
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
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              profileAsync.maybeWhen(
                                data: (profile) => Text(
                                  profile.name.trim().isNotEmpty ? profile.name : 'User',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? DarkColors.textPrimary
                                        : LightColors.textPrimary,
                                  ),
                                ),
                                orElse: () => Text(
                                  'Mostafa Kamel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? DarkColors.textPrimary
                                        : LightColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                'Editing Post',
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          focusNode: _textFocus,
                          controller: _textController,
                          maxLines: null,
                          maxLength: 500,
                          onChanged: (value) => ref
                              .read(editPostFormProvider(widget.post).notifier)
                              .updateContent(value),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                          decoration: InputDecoration(
                            hintText: 'What medicine or health question do you have?',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? DarkColors.textHint.withOpacity(0.5)
                                  : LightColors.textHint.withOpacity(0.5),
                              fontSize: 16,
                              height: 1.5,
                              letterSpacing: 0.2,
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
                              Expanded(
                                child: Text(
                                  formState.error!,
                                  style: const TextStyle(
                                    color: AppColors.accentRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 28),

                      // Image upload
                      const Text(
                        'Post Image',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? DarkColors.card
                                : LightColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isDark
                                  ? DarkColors.divider
                                  : LightColors.divider,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: (formState.pickedImagePath != null || (formState.existingImageUrl != null && !formState.hasRemovedImage))
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      child: formState.pickedImagePath != null
                                          ? Image.file(
                                              File(formState.pickedImagePath!),
                                              width: double.infinity,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              formState.existingImageUrl!,
                                              width: double.infinity,
                                              height: 200,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
                                                child: const Icon(
                                                  Icons.image_not_supported_rounded,
                                                  size: 48,
                                                  color: AppColors.primaryBlue,
                                                ),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          ref.read(editPostFormProvider(widget.post).notifier).clearImage();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.camera_alt_rounded,
                                                size: 14, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              'Tap to change image',
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
                                      'Add Image',
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
                      const SizedBox(height: 40),
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
