// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:Elaaj/features/pharmacies/model/user_pharmacy_model.dart';
import 'package:Elaaj/features/pharmacies/view/create_pharmacy/create_pharmacy_screen.dart';
import 'package:Elaaj/features/pharmacies/view/edit_pharmacy/edit_pharmacy_screen.dart';
import 'package:Elaaj/features/pharmacies/view/my_pharmacies/my_pharmacies_screen.dart';
import 'package:Elaaj/features/pharmacies/view/pharmacy_admins/pharmacy_admins_screen.dart';
import 'package:Elaaj/features/navigation/widgets/premium_nav_shell.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';

// ════════════════════════════════════════════════════════════════════════════
// PHARMACY DRAWER - PREMIUM REBUILD
// ════════════════════════════════════════════════════════════════════════════

class PharmacyDrawer extends ConsumerStatefulWidget {
  const PharmacyDrawer(this.pharmacy, {super.key});
  final UserPharmacyModel? pharmacy;

  @override
  ConsumerState<PharmacyDrawer> createState() => _PharmacyDrawerState();
}

class _PharmacyDrawerState extends ConsumerState<PharmacyDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    // Play entrance animation & load pharmacies lazily (once).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animCtrl.forward();
      _maybeLoadPharmacies();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Only triggers a network load when the list is empty — avoids
  /// re-fetching on every drawer open if data is already present.
  void _maybeLoadPharmacies() {
    final asyncPharmacies = ref.read(myPharmaciesProvider);
    if (asyncPharmacies is! AsyncData || asyncPharmacies.value == null) {
      ref.read(myPharmaciesProvider.notifier).loadUserPharmacies();
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _navigate(Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      _slideUpRoute(screen),
    );
  }

  static PageRoute<void> _slideUpRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // ── Pharmacy switching ────────────────────────────────────────────────────

  void _switchToPharmacy(UserPharmacyModel pharmacy, BuildContext sheetContext) {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Navigator.pop(sheetContext); // Close the bottom sheet safely
    Navigator.pop(context); // Close the drawer safely

    ref.read(pharmacyModeProvider.notifier).switchToPharmacyMode(pharmacy);
    ref.read(navigationIndexProvider.notifier).state = 0; // Force active tab to Pharmacy Profile (index 0)

    // Lightweight feedback — no dialog, no overlay, just a SnackBar.
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.business_rounded,
                  color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Switched to ${pharmacy.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor:
              isDark ? DarkColors.surface : LightColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ── Bottom-sheet: pharmacy selector ──────────────────────────────────────

  void _showPharmacySelector() {
    final state = ref.read(pharmacyModeProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _PharmacySelectorSheet(
        pharmacies: state.userPharmacies,
        currentPharmacyId: state.currentPharmacy?.id,
        onSelect: (pharmacy) => _switchToPharmacy(pharmacy, ctx),
        onCreateNew: () {
          Navigator.pop(ctx);
          _navigate(const CreatePharmacyScreen());
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pharmacyState = ref.watch(pharmacyModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.84,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (isDark ? DarkColors.surface : LightColors.surface)
                  .withOpacity(0.97),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppRadius.xxl),
                bottomRight: Radius.circular(AppRadius.xxl),
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _DrawerHeader(state: pharmacyState),

                      // Mode toggle
                      _ModeToggleSection(
                        state: pharmacyState,
                        onPersonalTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                          ref
                              .read(pharmacyModeProvider.notifier)
                              .switchToPersonalMode();
                        },
                        onPharmacyTap: () {
                          _showPharmacySelector();
                        },
                      ),

                      // Divider
                      Divider(
                        height: 1,
                        color: isDark
                            ? DarkColors.divider
                            : LightColors.divider,
                        indent: 20,
                        endIndent: 20,
                      ),

                      // Menu items
                      Expanded(
                        child: _MenuSection(
                          state: pharmacyState,
                          onMyPharmacies: () =>
                              _navigate(const MyPharmaciesScreen()),
                          onCreatePharmacy: () =>
                              _navigate(const CreatePharmacyScreen()),
                          onAdmins: pharmacyState.isPharmacyMode &&
                                  pharmacyState.currentPharmacy != null
                              ? () => _navigate(PharmacyAdminsScreen(
                                  pharmacy: pharmacyState.currentPharmacy!))
                              : null,
                          onEdit: pharmacyState.isPharmacyMode &&
                                  pharmacyState.currentPharmacy != null
                              ? () => _navigate(EditPharmacyScreen(
                                  pharmacy: pharmacyState.currentPharmacy!))
                              : null,
                        ),
                      ),

                      // Footer
                      _DrawerFooter(isDark: isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HEADER
// ════════════════════════════════════════════════════════════════════════════

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.state});
  final PharmacyModeState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon row
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pharmacy Hub',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.isPharmacyMode
                          ? (state.currentPharmacy?.name ?? 'Select Pharmacy')
                          : 'Personal Mode',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Active pharmacy badge (pharmacy mode only)
          if (state.isPharmacyMode && state.currentPharmacy != null) ...[
            const SizedBox(height: 14),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _PharmacyBadge(pharmacy: state.currentPharmacy!),
            ),
          ],
        ],
      ),
    );
  }
}

class _PharmacyBadge extends StatelessWidget {
  const _PharmacyBadge({required this.pharmacy});
  final UserPharmacyModel pharmacy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 13,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              pharmacy.address,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MODE TOGGLE
// ════════════════════════════════════════════════════════════════════════════

class _ModeToggleSection extends StatelessWidget {
  const _ModeToggleSection({
    required this.state,
    required this.onPersonalTap,
    required this.onPharmacyTap,
  });

  final PharmacyModeState state;
  final VoidCallback onPersonalTap;
  final VoidCallback onPharmacyTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE MODE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isDark ? DarkColors.textHint : LightColors.textHint,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? DarkColors.surfaceVariant
                  : LightColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Sliding indicator
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: state.isPersonalMode
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryBlue.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleButton(
                            label: 'Personal',
                            icon: Icons.person_rounded,
                            isActive: state.isPersonalMode,
                            onTap: onPersonalTap,
                          ),
                        ),
                        Expanded(
                          child: _ToggleButton(
                            label: 'Pharmacy',
                            icon: Icons.business_rounded,
                            isActive: state.isPharmacyMode,
                            badgeCount: state.userPharmacies.length,
                            onTap: onPharmacyTap,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
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
            if (!isActive && badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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

// ════════════════════════════════════════════════════════════════════════════
// MENU SECTION
// ════════════════════════════════════════════════════════════════════════════

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.state,
    required this.onMyPharmacies,
    required this.onCreatePharmacy,
    required this.onAdmins,
    required this.onEdit,
  });

  final PharmacyModeState state;
  final VoidCallback onMyPharmacies;
  final VoidCallback onCreatePharmacy;
  final VoidCallback? onAdmins;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // ── MANAGE ────────────────────────────────────────────────────────
        _SectionLabel(label: 'MANAGE', isDark: isDark),

        _DrawerMenuItem(
          icon: Icons.storefront_rounded,
          title: 'My Pharmacies',
          subtitle: 'View & manage your pharmacies',
          accentColor: AppColors.primaryBlue,
          isDark: isDark,
          onTap: onMyPharmacies,
        ),

        _DrawerMenuItem(
          icon: Icons.add_business_rounded,
          title: 'Create Pharmacy',
          subtitle: 'Register a new pharmacy',
          accentColor: AppColors.primaryGreen,
          isDark: isDark,
          onTap: onCreatePharmacy,
        ),

        const SizedBox(height: 4),

        // ── ADMINISTRATION ─────────────────────────────────────────────
        _SectionLabel(label: 'ADMINISTRATION', isDark: isDark),

        _DrawerMenuItem(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Pharmacy Admins',
          subtitle: !state.isPharmacyMode
              ? 'Switch to Pharmacy Mode first'
              : state.currentPharmacy == null
                  ? 'Select a pharmacy to continue'
                  : 'Manage admins for ${state.currentPharmacy!.name}',
          accentColor: AppColors.accentPurple,
          isDark: isDark,
          isEnabled: onAdmins != null,
          onTap: onAdmins,
          lockedReason: !state.isPharmacyMode
              ? _LockReason.notPharmacyMode
              : state.currentPharmacy == null
                  ? _LockReason.noPharmacySelected
                  : null,
        ),

        _DrawerMenuItem(
          icon: Icons.edit_rounded,
          title: 'Edit Pharmacy',
          subtitle: !state.isPharmacyMode
              ? 'Switch to Pharmacy Mode first'
              : state.currentPharmacy == null
                  ? 'Select a pharmacy to continue'
                  : 'Update details for ${state.currentPharmacy!.name}',
          accentColor: AppColors.accentYellow,
          isDark: isDark,
          isEnabled: onEdit != null,
          onTap: onEdit,
          lockedReason: !state.isPharmacyMode
              ? _LockReason.notPharmacyMode
              : state.currentPharmacy == null
                  ? _LockReason.noPharmacySelected
                  : null,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FOOTER
// ════════════════════════════════════════════════════════════════════════════

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_rounded,
              size: 18,
              color: AppColors.primaryBlue.withOpacity(0.8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Switch to Pharmacy Mode to manage your pharmacies and admins.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: isDark
                      ? DarkColors.textSecondary
                      : LightColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? DarkColors.textHint : LightColors.textHint,
        ),
      ),
    );
  }
}

enum _LockReason {
  notPharmacyMode,
  noPharmacySelected,
}

class _DrawerMenuItem extends StatefulWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
    this.isEnabled = true,
    this.onTap,
    this.lockedReason,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isDark;
  final bool isEnabled;
  final VoidCallback? onTap;
  final _LockReason? lockedReason;

  @override
  State<_DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<_DrawerMenuItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1, end: 0.97).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled && widget.onTap != null;
    final isDark = widget.isDark;
    final color = enabled
        ? widget.accentColor
        : (isDark ? DarkColors.textHint : LightColors.textHint);

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _press.forward() : null,
        onTapUp: enabled
            ? (_) {
                _press.reverse();
                widget.onTap?.call();
              }
            : null,
        onTapCancel: enabled ? () => _press.reverse() : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: enabled
                      ? widget.accentColor.withOpacity(isDark ? 0.14 : 0.1)
                      : (isDark
                          ? DarkColors.surfaceVariant
                          : LightColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  enabled ? widget.icon : Icons.lock_outline_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? (isDark
                                ? DarkColors.textPrimary
                                : LightColors.textPrimary)
                            : (isDark
                                ? DarkColors.textHint
                                : LightColors.textHint),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: enabled
                            ? (isDark
                                ? DarkColors.textSecondary
                                : LightColors.textSecondary)
                            : (isDark
                                ? DarkColors.textHint
                                : LightColors.textHint),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: enabled
                    ? (isDark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary)
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PHARMACY SELECTOR BOTTOM SHEET  (standalone, no context leaks)
// ════════════════════════════════════════════════════════════════════════════

class _PharmacySelectorSheet extends StatelessWidget {
  const _PharmacySelectorSheet({
    required this.pharmacies,
    required this.currentPharmacyId,
    required this.onSelect,
    required this.onCreateNew,
  });

  final List<UserPharmacyModel> pharmacies;
  final String? currentPharmacyId;
  final ValueChanged<UserPharmacyModel> onSelect;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? DarkColors.surface : LightColors.surface;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? DarkColors.divider : LightColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Select Pharmacy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color:
                    isDark ? DarkColors.textPrimary : LightColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              pharmacies.isEmpty
                  ? 'You have no pharmacies yet.'
                  : 'Choose a pharmacy to switch into pharmacy mode.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? DarkColors.textSecondary
                    : LightColors.textSecondary,
              ),
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? DarkColors.divider : LightColors.divider,
          ),

          // Empty state
          if (pharmacies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? DarkColors.surfaceVariant
                          : LightColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store_mall_directory_rounded,
                      size: 36,
                      color: isDark
                          ? DarkColors.textHint
                          : LightColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pharmacies Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? DarkColors.textPrimary
                          : LightColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your first pharmacy to get started.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? DarkColors.textSecondary
                          : LightColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                physics: const ClampingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: pharmacies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final pharmacy = pharmacies[index];
                  final isCurrent = pharmacy.id == currentPharmacyId;

                  return _PharmacyTile(
                    pharmacy: pharmacy,
                    isCurrent: isCurrent,
                    isDark: isDark,
                    onTap: () => onSelect(pharmacy),
                  );
                },
              ),
            ),

          Divider(
            height: 1,
            color: isDark ? DarkColors.divider : LightColors.divider,
          ),

          // Create button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Create New Pharmacy',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyTile extends StatefulWidget {
  const _PharmacyTile({
    required this.pharmacy,
    required this.isCurrent,
    required this.isDark,
    required this.onTap,
  });

  final UserPharmacyModel pharmacy;
  final bool isCurrent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_PharmacyTile> createState() => _PharmacyTileState();
}

class _PharmacyTileState extends State<_PharmacyTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isCurrent = widget.isCurrent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.primaryBlue.withOpacity(0.07)
              : isCurrent
                  ? AppColors.primaryBlue.withOpacity(isDark ? 0.12 : 0.06)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isCurrent
                ? AppColors.primaryBlue.withOpacity(0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.12)
                    : (isDark
                        ? DarkColors.surfaceVariant
                        : LightColors.surfaceVariant),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.business_rounded,
                color: isCurrent
                    ? AppColors.primaryBlue
                    : (isDark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pharmacy.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: isDark
                          ? DarkColors.textPrimary
                          : LightColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.pharmacy.address,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? DarkColors.textSecondary
                          : LightColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Active check
            if (isCurrent)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
