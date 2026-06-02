// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/auth/service/auth_service.dart';
import 'package:pharmacy_app/features/auth/controller/auth_providers.dart';
import 'package:pharmacy_app/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class UserSearchResult {
  final String userId;
  final String email;
  final String? fullName;

  const UserSearchResult({
    required this.userId,
    required this.email,
    this.fullName,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      userId: (json['id'] ?? json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: json['fullName'] as String?,
    );
  }

  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, AsyncValue<List<UserSearchResult>>>(
  (ref) => UserSearchNotifier(ref.read(authServiceProvider)),
);

class UserSearchNotifier
    extends StateNotifier<AsyncValue<List<UserSearchResult>>> {
  final AuthService _authService;

  UserSearchNotifier(this._authService) : super(const AsyncValue.data([]));

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await _authService.searchUsers(query: query.trim());
      state = AsyncValue.data(
        results.map((e) => UserSearchResult.fromJson(e)).toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class PharmacyAdminsScreen extends ConsumerStatefulWidget {
  final UserPharmacyModel pharmacy;

  const PharmacyAdminsScreen({super.key, required this.pharmacy});

  @override
  ConsumerState<PharmacyAdminsScreen> createState() =>
      _PharmacyAdminsScreenState();
}

class _PharmacyAdminsScreenState extends ConsumerState<PharmacyAdminsScreen>
    with SingleTickerProviderStateMixin {
  bool _isRemoving = false;
  late AnimationController _headerAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _removeAdmin(String userId) async {
    if (userId == widget.pharmacy.ownerUserId) {
      _showSnack('لا يمكن إزالة المالك', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'إزالة المسؤول',
      message: 'هل أنت متأكد أنك تريد إزالة هذا المسؤول؟',
      confirmLabel: 'إزالة',
      confirmColor: AppColors.accentRed,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRemoving = true);
    try {
      final ok = await ref
          .read(myPharmaciesProvider.notifier)
          .removeAdmin(widget.pharmacy.id, userId);
      if (mounted) {
        _showSnack(ok ? 'تمت إزالة المسؤول بنجاح' : 'فشل في إزالة المسؤول',
            isError: !ok);
      }
    } catch (e) {
      if (mounted) _showSnack('خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  Future<void> _openAddAdminSheet() async {
    // Reset search state
    ref.read(userSearchProvider.notifier).clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAdminSheet(
        pharmacyId: widget.pharmacy.id,
        onAdminAdded: () {
          ref.invalidate(myPharmaciesProvider);
        },
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.accentRed : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allAdminIds = widget.pharmacy.allAdminIds;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwner = widget.pharmacy.ownerUserId == currentUserId ||
        widget.pharmacy.ownerUserId.isEmpty;
    final isAdmin = widget.pharmacy.isAdmin(currentUserId);

    return Scaffold(
      backgroundColor:
          isDark ? DarkColors.background : LightColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Premium gradient app bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                final isCollapsed = top <= (MediaQuery.of(context).padding.top + kToolbarHeight + 20);

                return FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0EA5E9),
                          Color(0xFF8B5CF6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 38,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'إدارة المسؤولين',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.pharmacy.name,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  title: isCollapsed
                      ? const Text(
                          'إدارة المسؤولين',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                  collapseMode: CollapseMode.parallax,
                );
              },
            ),
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),

          // ── Stats strip ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatsStrip(
              adminCount: allAdminIds.length,
              pharmacyName: widget.pharmacy.name,
              isDark: isDark,
            ),
          ),

          // ── Section header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Text(
                    'المسؤولون (${allAdminIds.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? DarkColors.textPrimary
                          : LightColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_isRemoving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

          // ── Admin cards list ─────────────────────────────────────────────
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final userId = allAdminIds[index];
                  final isOwnerUser =
                      userId == widget.pharmacy.ownerUserId;
                  return _AdminCard(
                    userId: userId,
                    isOwner: isOwnerUser,
                    canRemove: isOwner && !isOwnerUser,
                    onRemove: () => _removeAdmin(userId),
                    isDark: isDark,
                  );
                },
                childCount: allAdminIds.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: _AddAdminFab(onTap: _openAddAdminSheet),
    );
  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final int adminCount;
  final String pharmacyName;
  final bool isDark;

  const _StatsStrip({
    required this.adminCount,
    required this.pharmacyName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(isDark ? 0.25 : 0.08),
            AppColors.accentPurple.withOpacity(isDark ? 0.25 : 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(isDark ? 0.4 : 0.15),
        ),
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.people_alt_rounded,
            label: 'المسؤولون',
            value: adminCount.toString(),
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 24),
          _StatItem(
            icon: Icons.local_pharmacy_rounded,
            label: 'الصيدلية',
            value: pharmacyName,
            color: AppColors.accentPurple,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Admin Card ───────────────────────────────────────────────────────────────

class _AdminCard extends StatelessWidget {
  final String userId;
  final bool isOwner;
  final bool canRemove;
  final VoidCallback onRemove;
  final bool isDark;

  const _AdminCard({
    required this.userId,
    required this.isOwner,
    required this.canRemove,
    required this.onRemove,
    required this.isDark,
  });

  Color get _roleColor =>
      isOwner ? AppColors.primaryBlue : AppColors.accentPurple;
  String get _roleLabel => isOwner ? 'مالك' : 'مسؤول';
  IconData get _roleIcon =>
      isOwner ? Icons.verified_rounded : Icons.shield_rounded;

  @override
  Widget build(BuildContext context) {
    final short = userId.length > 8 ? userId.substring(0, 8) : userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.card : LightColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? DarkColors.divider
              : LightColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: _roleColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _roleColor,
                _roleColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(_roleIcon, color: Colors.white, size: 22),
        ),
        title: Text(
          '$short...',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color:
                isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              _roleLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _roleColor,
              ),
            ),
          ),
        ),
        isThreeLine: false,
        trailing: canRemove
            ? PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'remove') onRemove();
                },
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.md)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.person_remove_rounded,
                              color: AppColors.accentRed, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text('إزالة المسؤول',
                            style: TextStyle(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

// ─── Add Admin FAB ────────────────────────────────────────────────────────────

class _AddAdminFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AddAdminFab({required this.onTap});

  @override
  State<_AddAdminFab> createState() => _AddAdminFabState();
}

class _AddAdminFabState extends State<_AddAdminFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.accentPurple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'إضافة أدمن جديد',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add Admin Bottom Sheet ───────────────────────────────────────────────────

class _AddAdminSheet extends ConsumerStatefulWidget {
  final String pharmacyId;
  final VoidCallback onAdminAdded;

  const _AddAdminSheet({
    required this.pharmacyId,
    required this.onAdminAdded,
  });

  @override
  ConsumerState<_AddAdminSheet> createState() => _AddAdminSheetState();
}

class _AddAdminSheetState extends ConsumerState<_AddAdminSheet> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String? _assigningId;
  String? _successId;

  @override
  void initState() {
    super.initState();
    // Auto focus search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String val) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        ref.read(userSearchProvider.notifier).searchUsers(val);
      }
    });
  }

  Future<void> _assign(UserSearchResult user) async {
    if (_assigningId != null) return;
    setState(() {
      _assigningId = user.userId;
      _successId = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.assignPharmacyAdmin(
        userId: user.userId,
        pharmacyId: widget.pharmacyId,
      );

      if (!mounted) return;
      setState(() {
        _successId = user.userId;
        _assigningId = null;
      });

      widget.onAdminAdded();

      // Brief success pulse then pop
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${user.displayName} تمت إضافته كمسؤول بنجاح ✓'),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigningId = null);

      String errMsg = e.toString();
      // Extract Arabic message from API if present
      if (errMsg.contains('تم')) {
        errMsg = 'هذا المستخدم مسؤول بالفعل في هذه الصيدلية';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchState = ref.watch(userSearchProvider);
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? DarkColors.divider
                    : LightColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.accentPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إضافة أدمن جديد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? DarkColors.textPrimary
                            : LightColors.textPrimary,
                      ),
                    ),
                    Text(
                      'ابحث باسم المستخدم أو البريد الإلكتروني',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? DarkColors.textSecondary
                            : LightColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
              height: 1,
              color: isDark ? DarkColors.divider : LightColors.divider),

          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? DarkColors.surfaceVariant
                    : LightColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.primaryBlue.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onChanged: _onSearch,
                style: TextStyle(
                  color: isDark
                      ? DarkColors.textPrimary
                      : LightColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مستخدم...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? DarkColors.textHint
                        : LightColors.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _searchCtrl.text.isNotEmpty
                        ? AppColors.primaryBlue
                        : (isDark
                            ? DarkColors.textSecondary
                            : LightColors.textSecondary),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref
                                .read(userSearchProvider.notifier)
                                .clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: searchState.when(
              data: (users) {
                if (_searchCtrl.text.trim().isEmpty) {
                  return _EmptySearchPrompt(isDark: isDark);
                }
                if (users.isEmpty) {
                  return _NoResults(
                      query: _searchCtrl.text, isDark: isDark);
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final user = users[i];
                    final isAssigning =
                        _assigningId == user.userId;
                    final isSuccess = _successId == user.userId;
                    return _UserResultCard(
                      user: user,
                      isAssigning: isAssigning,
                      isSuccess: isSuccess,
                      isDisabled: _assigningId != null,
                      onAssign: () => _assign(user),
                      isDark: isDark,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                          AppColors.primaryBlue),
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 16),
                    Text('جارٍ البحث...'),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.accentRed),
                    const SizedBox(height: 12),
                    Text(
                      'حدث خطأ أثناء البحث',
                      style: TextStyle(
                          color: isDark
                              ? DarkColors.textPrimary
                              : LightColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User Result Card ─────────────────────────────────────────────────────────

class _UserResultCard extends StatelessWidget {
  final UserSearchResult user;
  final bool isAssigning;
  final bool isSuccess;
  final bool isDisabled;
  final VoidCallback onAssign;
  final bool isDark;

  const _UserResultCard({
    required this.user,
    required this.isAssigning,
    required this.isSuccess,
    required this.isDisabled,
    required this.onAssign,
    required this.isDark,
  });

  Color get _avatarColor {
    final colors = [
      AppColors.primaryBlue,
      AppColors.accentPurple,
      AppColors.primaryGreen,
      AppColors.accentYellow,
      AppColors.primaryCyan,
    ];
    final idx = user.userId.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppColors.primaryGreen.withOpacity(isDark ? 0.15 : 0.07)
            : (isDark ? DarkColors.card : LightColors.card),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isSuccess
              ? AppColors.primaryGreen.withOpacity(0.4)
              : isAssigning
                  ? AppColors.primaryBlue.withOpacity(0.3)
                  : (isDark ? DarkColors.divider : LightColors.divider),
          width: isSuccess || isAssigning ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _avatarColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _avatarColor,
                _avatarColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          user.fullName?.isNotEmpty == true ? user.fullName! : 'بدون اسم',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            user.email,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
        ),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isSuccess
              ? Container(
                  key: const ValueKey('success'),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.primaryGreen, size: 24),
                )
              : isAssigning
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                            AppColors.primaryBlue),
                      ),
                    )
                  : _AssignButton(
                      key: const ValueKey('btn'),
                      onTap: isDisabled ? null : onAssign,
                    ),
        ),
      ),
    );
  }
}

// ─── Assign Button ────────────────────────────────────────────────────────────

class _AssignButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _AssignButton({super.key, required this.onTap});

  @override
  State<_AssignButton> createState() => _AssignButtonState();
}

class _AssignButtonState extends State<_AssignButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => _ctrl.forward() : null,
      onTapUp: enabled
          ? (_) {
              _ctrl.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.accentPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: enabled ? null : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: enabled ? Colors.white : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'إضافة',
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty & No-Results States ────────────────────────────────────────────────

class _EmptySearchPrompt extends StatelessWidget {
  final bool isDark;
  const _EmptySearchPrompt({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.15),
                  AppColors.accentPurple.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_search_rounded,
              size: 48,
              color: AppColors.primaryBlue.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ابحث عن مستخدم',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اكتب الاسم أو البريد الإلكتروني\nللمستخدم الذي تريد إضافته',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark
                  ? DarkColors.textSecondary
                  : LightColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final bool isDark;
  const _NoResults({required this.query, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.accentRed.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على مستخدم\nيطابق "$query"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark
                  ? DarkColors.textSecondary
                  : LightColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
