// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/core/routing/app_routes.dart';
import 'package:pharmacy_app/features/home/model/quick_action_model.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? DarkColors.textPrimary : LightColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryGreen,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRadius.xs)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: AppTypography.h3.fontSize,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: _kActions
                .map((action) =>
                    Expanded(child: _PillActionCard(action: action)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Static const action definitions — avoids creating new QuickActionModel
/// instances on every build. 
/// 
/// Because BuildContext is unavailable at compile-time, `onTap` is given 
/// a no-op `(){}`. The actual navigation is handled securely inside 
/// `_PillActionCard._handleAction()` where a valid BuildContext exists.
const _kActions = <QuickActionModel>[
  QuickActionModel(
    id: '1',
    title: 'Upload Rx',
    icon: Icons.document_scanner_rounded,
    iconColor: AppColors.primaryGreen,
    gradient: [AppColors.primaryGreen, Color(0xFF34D399)],
    onTap: _noop, // No-op to allow const
  ),
  QuickActionModel(
    id: '2',
    title: 'Ask Now',
    icon: Icons.chat_bubble_rounded,
    iconColor: AppColors.primaryBlue,
    gradient: [AppColors.primaryBlue, Color(0xFF38BDF8)],
    onTap: _noop, // No-op to allow const
  ),
];

/// Top-level no-op function. Defining it as a top-level constant ensures
/// the exact same function identity is reused, preventing unnecessary
/// widget rebuilds if Riverpod/Flutter compares callback identities.
void _noop() {}

class _PillActionCard extends StatefulWidget {
  final QuickActionModel action;

  const _PillActionCard({required this.action});

  @override
  State<_PillActionCard> createState() => _PillActionCardState();
}

class _PillActionCardState extends State<_PillActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Cached objects that are used on every animation frame —
  // avoids reallocating during the 60fps scale animation.
  late final LinearGradient _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: widget.action.gradient,
  );

  late final Color _shadowColor = Color.fromRGBO(
    widget.action.iconColor.red,
    widget.action.iconColor.green,
    widget.action.iconColor.blue,
    0.3,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();

  void _onTapUp(TapUpDetails details) {
    _controller.reverse().then((_) => _handleAction());
  }

  void _onTapCancel() => _controller.reverse();

  /// Handles the actual navigation using the current BuildContext.
  /// This safely replaces the compile-time no-op callbacks.
  void _handleAction() {
    switch (widget.action.id) {
      case '1':
        context.push(AppRoutes.uploadPrescription);
        break;
      case '2':
        // Ask Now — no-op placeholder
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
    );
  }
}