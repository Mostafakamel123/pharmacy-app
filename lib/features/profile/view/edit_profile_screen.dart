import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/profile/controller/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Delay initialization until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).asData?.value;
      if (profile != null) {
        ref.read(editFormProvider.notifier).initialize(
              profile.name,
              profile.phone,
              profile.location,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(editFormProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor:
            isDark ? DarkColors.background : LightColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: formState.isSaving
                ? null
                : () async {
                    final success =
                        await ref.read(editFormProvider.notifier).save();
                    if (success) {
                      final name = formState.name;
                      final phone = formState.phone;
                      final location = formState.location;
                      await ref
                          .read(profileProvider.notifier)
                          .updateProfile(
                            name: name,
                            phone: phone,
                            location: location,
                          );
                      if (context.mounted) context.pop();
                    }
                  },
            child: formState.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : Text(
                    'Save',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar section
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? DarkColors.divider
                          : LightColors.divider,
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Name field
            _InputField(
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_rounded,
              initialValue: formState.name,
              onChanged: (v) =>
                  ref.read(editFormProvider.notifier).updateName(v),
              error: formState.errors['name'],
            ),
            const SizedBox(height: 16),

            // Phone field
            _InputField(
              label: 'Phone Number',
              hint: 'Enter your phone number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              initialValue: formState.phone,
              onChanged: (v) =>
                  ref.read(editFormProvider.notifier).updatePhone(v),
              error: formState.errors['phone'],
            ),
            const SizedBox(height: 16),

            // Location field
            _InputField(
              label: 'Location',
              hint: 'City, Area (optional)',
              icon: Icons.location_on_rounded,
              initialValue: formState.location,
              onChanged: (v) =>
                  ref.read(editFormProvider.notifier).updateLocation(v),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? error;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.initialValue,
    required this.onChanged,
    this.error,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_InputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? DarkColors.card : LightColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.error != null
                  ? AppColors.accentRed
                  : isDark
                      ? DarkColors.divider
                      : LightColors.divider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: isDark ? DarkColors.textHint : LightColors.textHint,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: widget.error != null
                    ? AppColors.accentRed
                    : isDark
                        ? const Color(0xFF90CAF9)
                        : AppColors.primaryBlue,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.error!,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
