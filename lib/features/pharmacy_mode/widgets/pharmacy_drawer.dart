// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:pharmacy_app/features/pharmacies/view/create_pharmacy/create_pharmacy_screen.dart';
import 'package:pharmacy_app/features/pharmacies/view/edit_pharmacy/edit_pharmacy_screen.dart';
import 'package:pharmacy_app/features/pharmacies/view/my_pharmacies/my_pharmacies_screen.dart';
import 'package:pharmacy_app/features/pharmacies/view/pharmacy_admins/pharmacy_admins_screen.dart';

/// Pharmacy Drawer - Provides access to pharmacy management features
/// and allows switching between pharmacy modes
class PharmacyDrawer extends ConsumerStatefulWidget {
  const PharmacyDrawer(this.pharmacy, {super.key});
  final UserPharmacyModel? pharmacy;

  @override
  ConsumerState<PharmacyDrawer> createState() => _PharmacyDrawerState();
}

class _PharmacyDrawerState extends ConsumerState<PharmacyDrawer> {
  @override
  Widget build(BuildContext context) {
    final pharmacyModeState = ref.watch(pharmacyModeProvider);
    final notifier = ref.read(pharmacyModeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: isDark ? DarkColors.surface : LightColors.surface,
      elevation: 16,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: RepaintBoundary(
        child: Column(
          children: [
            // Header with gradient background
            _buildHeader(context, pharmacyModeState, isDark),
            // Mode toggle section
            _buildModeToggleSection(context, notifier, pharmacyModeState),
            // Menu items
            Expanded(
              child: _buildMenuItems(context, notifier, pharmacyModeState),
            ),
            // Footer
            _buildFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    PharmacyModeState state,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pharmacy Hub',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isPharmacyMode
                          ? state.currentPharmacy?.name ?? 'Select Pharmacy'
                          : 'Personal Mode',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.isPharmacyMode && state.currentPharmacy != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      state.currentPharmacy!.address,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeToggleSection(
    BuildContext context,
    PharmacyModeNotifier notifier,
    PharmacyModeState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? DarkColors.textHint : LightColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? DarkColors.surfaceVariant
                  : LightColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _ModeToggleButton(
                    label: 'Personal',
                    icon: Icons.person_outline,
                    isActive: state.isPersonalMode,
                    onTap: () => notifier.switchToPersonalMode(),
                  ),
                ),
                Expanded(
                  child: _ModeToggleButton(
                    label: 'Pharmacy',
                    icon: Icons.business_outlined,
                    isActive: state.isPharmacyMode,
                    onTap: () {
                      Navigator.pop(context);
                      _showPharmacySelector(context, ref);
                    },
                    badgeCount: state.userPharmacies.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(
    BuildContext context,
    PharmacyModeNotifier notifier,
    PharmacyModeState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        // Manage Pharmacies Section
        _buildSectionTitle('Manage', isDark),
        _MenuItem(
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront,
          title: 'My Pharmacies',
          subtitle: 'View & manage your pharmacies',
          iconColor: AppColors.primaryBlue,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const MyPharmaciesScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
        _MenuItem(
          icon: Icons.add_business_outlined,
          activeIcon: Icons.add_business,
          title: 'Create Pharmacy',
          subtitle: 'Add a new pharmacy',
          iconColor: AppColors.primaryGreen,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const CreatePharmacyScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Administration Section
        _buildSectionTitle('Administration', isDark),
        _MenuItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          title: 'Pharmacy Admins',
          subtitle: 'Manage administrators',
          iconColor: AppColors.accentPurple,
          isDark: isDark, // Assuming isDark is defined nearby
          isEnabled: state.isPharmacyMode && state.currentPharmacy != null,
          onTap: () {
            // Check if pharmacy exists before navigating
            if (state.currentPharmacy == null) {
              Navigator.pop(context); // Close drawer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a pharmacy first'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    PharmacyAdminsScreen(pharmacy: state.currentPharmacy!),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
        _MenuItem(
          icon: Icons.edit_outlined,
          activeIcon: Icons.edit,
          title: 'Edit Pharmacy',
          subtitle: 'Update pharmacy details',
          iconColor: AppColors.accentYellow,
          isDark: isDark,
          isEnabled: state.isPharmacyMode && state.currentPharmacy != null,
          onTap: () {
            Navigator.pop(context);
            if (state.currentPharmacy != null) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      EditPharmacyScreen(pharmacy: state.currentPharmacy!),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    );
                  },
                ),
              );
            } else {
              _showSelectPharmacySnackbar(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? DarkColors.textHint : LightColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? DarkColors.surfaceVariant
              : LightColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pharmacy Mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? DarkColors.textPrimary
                          : LightColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Switch modes to manage pharmacies',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? DarkColors.textSecondary
                          : LightColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPharmacySelector(BuildContext context, WidgetRef ref) {
    final state = ref.read(pharmacyModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? DarkColors.surface
              : LightColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkColors.textHint
                          : LightColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select Pharmacy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? DarkColors.textPrimary
                        : LightColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose a pharmacy to manage',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              if (state.userPharmacies.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 64,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? DarkColors.textHint
                            : LightColors.textHint,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Pharmacies Yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkColors.textPrimary
                              : LightColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first pharmacy to start managing',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkColors.textSecondary
                              : LightColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: state.userPharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = state.userPharmacies[index];
                      final isCurrentPharmacy =
                          state.currentPharmacy?.id == pharmacy.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isCurrentPharmacy
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? DarkColors.surfaceVariant
                                      : LightColors.surfaceVariant),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            Icons.business_rounded,
                            color: isCurrentPharmacy
                                ? AppColors.primaryBlue
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? DarkColors.textSecondary
                                      : LightColors.textSecondary),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          pharmacy.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isCurrentPharmacy
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? DarkColors.textPrimary
                                : LightColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          pharmacy.address,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? DarkColors.textSecondary
                                : LightColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isCurrentPharmacy
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _switchPharmacyWithTransition(context, ref, pharmacy);
                        },
                      );
                    },
                  ),
                ),
              ],
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            const CreatePharmacyScreen(),
                        transitionsBuilder: (_, animation, __, child) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('Create New Pharmacy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Switch pharmacy with smooth loading transition (Facebook-style)
  void _switchPharmacyWithTransition(
    BuildContext context,
    WidgetRef ref,
    dynamic pharmacy,
  ) {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? DarkColors.surface
                : LightColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
              const SizedBox(height: 12),
              Text(
                'Switching...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? DarkColors.textPrimary
                      : LightColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate loading delay then switch
    Future.delayed(const Duration(milliseconds: 1200), () {
      // Switch pharmacy mode
      ref
          .read(pharmacyModeProvider.notifier)
          .switchToPharmacyMode(pharmacy);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(dialogContext).pop();

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Switched to ${pharmacy.name}'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? DarkColors.surface
                : LightColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showSelectPharmacySnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please select a pharmacy first'),
        backgroundColor: AppColors.accentYellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        action: SnackBarAction(
          label: 'Select',
          textColor: Colors.black,
          onPressed: () {
            _showPharmacySelector(context, ref);
          },
        ),
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final int? badgeCount;

  const _ModeToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Colors.white
                  : (isDark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (isDark
                          ? DarkColors.textSecondary
                          : LightColors.textSecondary),
              ),
            ),
            if (badgeCount != null && badgeCount! > 0 && !isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool isDark;
  final bool isEnabled;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.isDark,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: isEnabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isEnabled
              ? iconColor.withOpacity(0.1)
              : (isDark
                    ? DarkColors.surfaceVariant
                    : LightColors.surfaceVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          isEnabled ? icon : Icons.lock_outline,
          color: isEnabled
              ? iconColor
              : (isDark ? DarkColors.textHint : LightColors.textHint),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isEnabled
              ? (isDark ? DarkColors.textPrimary : LightColors.textPrimary)
              : (isDark ? DarkColors.textHint : LightColors.textHint),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isEnabled
              ? (isDark ? DarkColors.textSecondary : LightColors.textSecondary)
              : (isDark ? DarkColors.textHint : LightColors.textHint),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isEnabled
            ? (isDark ? DarkColors.textSecondary : LightColors.textSecondary)
            : (isDark ? DarkColors.textHint : LightColors.textHint),
        size: 20,
      ),
      onTap: isEnabled ? onTap : null,
    );
  }
}
