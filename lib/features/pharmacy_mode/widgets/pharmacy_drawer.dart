// ignore_for_file: deprecated_member_use

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

    // Kept short (180ms) for a snappy feel — BackdropFilter removed to avoid
    // per-frame GPU blur cost which was the main source of jank.
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.03, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

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
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
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
    final surfaceColor = isDark ? DarkColors.surface : LightColors.surface;
    final dividerColor = isDark ? DarkColors.divider : LightColors.divider;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.84,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
        // BackdropFilter removed — it was running an expensive GPU blur on
        // every animation frame, causing the drawer open/close jank.
        // A solid slightly-transparent surface achieves the same look at
        // zero extra GPU cost.
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(0.98),
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
                    // ── Fixed top: Header + Mode Toggle ──────────────────
                    _DrawerHeader(state: pharmacyState),

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

                    Divider(height: 1, color: dividerColor, indent: 20, endIndent: 20),

                    // ── Scrollable middle section ─────────────────────────
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Quick pharmacies list with Owner/Admin badges
                          if (pharmacyState.userPharmacies.isNotEmpty)
                            _PharmaciesQuickList(
                              pharmacies: pharmacyState.userPharmacies,
                              currentPharmacyId: pharmacyState.currentPharmacy?.id,
                              isDark: isDark,
                              onSwitchTap: () => _showPharmacySelector(),
                            ),

                          if (pharmacyState.userPharmacies.isNotEmpty)
                            Divider(height: 1, color: dividerColor, indent: 20, endIndent: 20),

                          // Menu items
                          _MenuSection(
                            state: pharmacyState,
                            onMyPharmacies: () =>
                                _navigate(const MyPharmaciesScreen()),
                            onCreatePharmacy: () =>
                                _navigate(const CreatePharmacyScreen()),
                            onAdmins: pharmacyState.isPharmacyMode &&
                                    pharmacyState.currentPharmacy != null &&
                                    (pharmacyState.currentPharmacy!.isOwnerRole)
                                ? () => _navigate(PharmacyAdminsScreen(
                                    pharmacy: pharmacyState.currentPharmacy!))
                                : null,
                            onEdit: pharmacyState.isPharmacyMode &&
                                    pharmacyState.currentPharmacy != null &&
                                    (pharmacyState.currentPharmacy!.isOwnerRole)
                                ? () => _navigate(EditPharmacyScreen(
                                    pharmacy: pharmacyState.currentPharmacy!))
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // ── Fixed bottom: Footer ──────────────────────────────
                    _DrawerFooter(isDark: isDark),
                  ],
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
    final isOwner = pharmacy.isOwnerRole;
    final roleColor = isOwner ? const Color(0xFF60A5FA) : const Color(0xFF34D399);
    final roleLabel = isOwner ? 'Owner' : 'Admin';
    final roleIcon = isOwner ? Icons.verified_rounded : Icons.admin_panel_settings_rounded;

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
          const SizedBox(width: 8),
          // Role badge inline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: roleColor.withOpacity(0.5), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, color: roleColor, size: 10),
                const SizedBox(width: 3),
                Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
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
      ),
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
// PHARMACIES QUICK LIST  (visible directly in drawer — shows Owner / Admin roles)
// ════════════════════════════════════════════════════════════════════════════

class _PharmaciesQuickList extends StatelessWidget {
  const _PharmaciesQuickList({
    required this.pharmacies,
    required this.currentPharmacyId,
    required this.isDark,
    required this.onSwitchTap,
  });

  final List<UserPharmacyModel> pharmacies;
  final String? currentPharmacyId;
  final bool isDark;
  final VoidCallback onSwitchTap;

  @override
  Widget build(BuildContext context) {
    final sorted = [
      ...pharmacies.where((p) => p.isOwnerRole),
      ...pharmacies.where((p) => p.isAdminOnlyRole),
    ];
    final ownedCount = pharmacies.where((p) => p.isOwnerRole).length;
    final adminCount = pharmacies.where((p) => p.isAdminOnlyRole).length;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final textHint = isDark ? DarkColors.textHint : LightColors.textHint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header row
          Row(
            children: [
              Text(
                'MY PHARMACIES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: textHint,
                ),
              ),
              const Spacer(),
              if (ownedCount > 0)
                _SmallCountBadge(count: ownedCount, label: 'Owner', color: AppColors.primaryBlue),
              if (ownedCount > 0 && adminCount > 0) const SizedBox(width: 4),
              if (adminCount > 0)
                _SmallCountBadge(count: adminCount, label: 'Admin', color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSwitchTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 12, color: AppColors.primaryBlue),
                      const SizedBox(width: 3),
                      Text('Switch',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Pharmacy rows
          ...sorted.asMap().entries.map((entry) {
            final idx = entry.key;
            final pharmacy = entry.value;
            final isActive = pharmacy.id == currentPharmacyId;
            final isOwner = pharmacy.isOwnerRole;
            final roleColor = isOwner ? AppColors.primaryBlue : AppColors.primaryGreen;
            final roleLabel = isOwner ? 'Owner' : 'Admin';
            final roleIcon = isOwner ? Icons.verified_rounded : Icons.admin_panel_settings_rounded;
            final showAdminDivider = ownedCount > 0 && adminCount > 0 && idx == ownedCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showAdminDivider)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(height: 1, width: 12, color: AppColors.primaryGreen.withOpacity(0.2)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            'ADMIN ACCESS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primaryGreen.withOpacity(0.7),
                            ),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: AppColors.primaryGreen.withOpacity(0.15))),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: onSwitchTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? roleColor.withOpacity(isDark ? 0.15 : 0.07) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isActive ? roleColor.withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Glowing dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? roleColor : roleColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [BoxShadow(color: roleColor.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Name
                        Expanded(
                          child: Text(
                            pharmacy.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? (isDark ? DarkColors.textPrimary : LightColors.textPrimary)
                                  : textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Role chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: roleColor.withOpacity(0.3), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, color: roleColor, size: 9),
                              const SizedBox(width: 3),
                              Text(
                                roleLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: roleColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SmallCountBadge extends StatelessWidget {
  const _SmallCountBadge({required this.count, required this.label, required this.color});

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.25), width: 0.8),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
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
            child: Builder(builder: (context) {
              final ownerCount = pharmacies.where((p) => p.isOwnerRole).length;
              final adminCount = pharmacies.where((p) => p.isAdminOnlyRole).length;
              String subtitle;
              if (pharmacies.isEmpty) {
                subtitle = 'You have no pharmacies yet.';
              } else if (ownerCount > 0 && adminCount > 0) {
                subtitle = '$ownerCount owned · $adminCount admin — tap to switch';
              } else if (ownerCount > 0) {
                subtitle = '$ownerCount pharmacy${ownerCount > 1 ? "s" : ""} owned by you';
              } else {
                subtitle = '$adminCount pharmacy${adminCount > 1 ? "s" : ""} where you are admin';
              }
              return Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? DarkColors.textSecondary
                      : LightColors.textSecondary,
                ),
              );
            }),
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
                // Sort: owned pharmacies first, then admin pharmacies
                itemCount: pharmacies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  // Build sorted list: owners first
                  final sorted = [
                    ...pharmacies.where((p) => p.isOwnerRole),
                    ...pharmacies.where((p) => p.isAdminOnlyRole),
                  ];
                  final pharmacy = sorted[index];
                  final isCurrent = pharmacy.id == currentPharmacyId;

                  // Add a section divider between owned and admin pharmacies
                  final ownedCount = pharmacies.where((p) => p.isOwnerRole).length;
                  final adminCount = pharmacies.where((p) => p.isAdminOnlyRole).length;
                  final showAdminHeader = ownedCount > 0 && adminCount > 0 && index == ownedCount;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0 && ownedCount > 0)
                        _RoleSectionHeader(
                          label: 'YOUR PHARMACIES',
                          icon: Icons.verified_rounded,
                          color: AppColors.primaryBlue,
                          isDark: isDark,
                        ),
                      if (showAdminHeader)
                        _RoleSectionHeader(
                          label: 'ADMIN ACCESS',
                          icon: Icons.admin_panel_settings_rounded,
                          color: AppColors.primaryGreen,
                          isDark: isDark,
                        ),
                      _PharmacyTile(
                        pharmacy: pharmacy,
                        isCurrent: isCurrent,
                        isDark: isDark,
                        onTap: () => onSelect(pharmacy),
                      ),
                    ],
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
    final isOwner = widget.pharmacy.isOwnerRole;
    final roleColor = isOwner ? AppColors.primaryBlue : AppColors.primaryGreen;
    final roleLabel = isOwner ? 'Owner' : 'Admin';
    final roleIcon = isOwner ? Icons.verified_rounded : Icons.admin_panel_settings_rounded;

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
              ? roleColor.withOpacity(0.07)
              : isCurrent
                  ? roleColor.withOpacity(isDark ? 0.12 : 0.06)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isCurrent
                ? roleColor.withOpacity(0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Avatar — color reflects ownership
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCurrent
                    ? roleColor.withOpacity(isDark ? 0.2 : 0.12)
                    : (isDark
                        ? DarkColors.surfaceVariant
                        : LightColors.surfaceVariant),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.business_rounded,
                color: isCurrent
                    ? roleColor
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: roleColor.withOpacity(0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, color: roleColor, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: roleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
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
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active check or role indicator
            if (isCurrent)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: roleColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? DarkColors.textHint : LightColors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROLE SECTION HEADER  (divider between owned and admin pharmacies)
// ════════════════════════════════════════════════════════════════════════════

class _RoleSectionHeader extends StatelessWidget {
  const _RoleSectionHeader({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: color.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
