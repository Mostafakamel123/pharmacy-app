import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:Elaaj/core/routing/app_routes.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/home/model/quick_action_model.dart';
import 'package:Elaaj/features/posts/view/create_post_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// QUICK ACTIONS SECTION
// ════════════════════════════════════════════════════════════════════════════

/// Two-pill action row linking to key patient flows.
///
/// Performance notes:
/// • [QuickActionsSection] is a pure [StatelessWidget] with only const
///   children. Flutter's element-reuse mechanism skips diffing the entire
///   subtree on parent rebuilds.
/// • The action data list `_kActions` is a top-level const — zero heap
///   allocation per build call.
/// • The press animation uses a single [AnimationController] per card
///   ([_PressableActionCard]), scoped tightly to avoid unnecessary tickers
///   at the section level.
/// • [ScaleTransition] drives the animation directly from the controller's
///   value without rebuilding the subtree via setState — it attaches a
///   listener to the [RenderTransform] layer directly.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? DarkColors.textPrimary : LightColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section title with gradient accent bar ───────────────────
          Row(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
                ),
                child: SizedBox(width: 4, height: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: AppTypography.h3.fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // ── Action pills ─────────────────────────────────────────────
          Row(
            children: _kActions
                .map((a) => Expanded(child: _PressableActionCard(action: a)))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ACTION DEFINITIONS  (compile-time constants — zero runtime allocation)
// ════════════════════════════════════════════════════════════════════════════

const _kActions = <QuickActionModel>[
  QuickActionModel(
    id: '1',
    title: 'Upload Rx',
    icon: Icons.document_scanner_rounded,
    iconColor: AppColors.primaryGreen,
    gradient: [AppColors.primaryGreen, Color(0xFF34D399)],
    onTap: _noop,
  ),
  QuickActionModel(
    id: '2',
    title: 'Ask Now',
    icon: Icons.chat_bubble_rounded,
    iconColor: AppColors.primaryBlue,
    gradient: [AppColors.primaryBlue, Color(0xFF38BDF8)],
    onTap: _noop,
  ),
];

/// Top-level no-op keeps the same function identity across builds,
/// preventing spurious inequality checks in QuickActionModel.
void _noop() {}

// ════════════════════════════════════════════════════════════════════════════
// PRESSABLE ACTION CARD
// ════════════════════════════════════════════════════════════════════════════

class _PressableActionCard extends StatefulWidget {
  final QuickActionModel action;
  const _PressableActionCard({required this.action});

  @override
  State<_PressableActionCard> createState() => _PressableActionCardState();
}

class _PressableActionCardState extends State<_PressableActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  // Pre-compute gradient & shadow — avoids re-allocating on every frame
  // during the 100 ms press animation.
  late final LinearGradient _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: widget.action.gradient,
  );

  late final Color _shadowColor = Color.fromRGBO(
    widget.action.iconColor.red,
    widget.action.iconColor.green,
    widget.action.iconColor.blue,
    0.30,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();

  void _onTapUp(TapUpDetails _) =>
      _ctrl.reverse().then((_) => _handleAction());

  void _onTapCancel() => _ctrl.reverse();

  void _handleAction() {
    switch (widget.action.id) {
      case '1':
        context.push(AppRoutes.uploadPrescription);
        break;
      case '2':
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const CreatePostScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppRadius.xl)),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.action.icon, size: 22, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.action.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
