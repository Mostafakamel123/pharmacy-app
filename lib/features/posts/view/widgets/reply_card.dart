// ignore_for_file: deprecated_member_use, dead_code

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/features/posts/model/post_model.dart';

class ReplyCard extends ConsumerWidget {
  final ReplyModel reply;
  final bool isBestReply;

  const ReplyCard({
    super.key,
    required this.reply,
    this.isBestReply = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPharmacyMode = ref.watch(isPharmacyModeProvider);

    final showBestReplyHighlight = isBestReply && isPharmacyMode;

    // Derived theme colors
    final cardColor = switch (showBestReplyHighlight) {
      true => AppColors.primaryGreen.withOpacity(isDark ? 0.08 : 0.05),
      false => isDark ? DarkColors.card : LightColors.card,
    };
    final borderColor = showBestReplyHighlight
        ? AppColors.primaryGreen.withOpacity(0.3)
        : (isDark ? DarkColors.divider : LightColors.divider);
    final borderWidth = showBestReplyHighlight ? 2.0 : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(showBestReplyHighlight, isDark),
          const SizedBox(height: 10),
          _buildContent(isDark),
          if (reply.medicineName != null) ...[
            const SizedBox(height: 10),
            _buildMedicineInfo(isDark),
          ],
          // Actions hidden for now (normal user view)
        ],
      ),
    );
  }

  Widget _buildHeader(bool isBest, bool isDark) {
    return Row(
      children: [
        _buildAvatar(isBest),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameRow(isBest, isDark),
              const SizedBox(height: 2),
              Text(
                reply.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? DarkColors.textHint : LightColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(bool isBest) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isBest
            ? const LinearGradient(
                colors: [AppColors.primaryGreen, Color(0xFF34D399)],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Icon(
        Icons.local_pharmacy_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildNameRow(bool isBest, bool isDark) {
    final nameColor = isBest
        ? AppColors.primaryGreen
        : (isDark ? DarkColors.textPrimary : LightColors.textPrimary);

    return Row(
      children: [
        Expanded(
          child: Text(
            reply.pharmacyName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: nameColor,
            ),
          ),
        ),
        if (reply.isVerified) const _VerifiedBadge(),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    return Text(
      reply.content,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildMedicineInfo(bool isDark) {
    final iconColor = isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue;
    final surfaceColor = isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.medication_rounded, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.medicineName!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                ),
                Text(
                  reply.isAvailable ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: reply.isAvailable
                        ? AppColors.primaryGreen
                        : AppColors.accentRed,
                  ),
                ),
              ],
            ),
          ),
          if (reply.price != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'EGP ${reply.price!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 12, color: AppColors.primaryBlue),
          const SizedBox(width: 3),
          const Text(
            'Verified',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
