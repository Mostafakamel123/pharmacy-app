// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';

class ReplyCard extends StatelessWidget {
  final ReplyModel reply;
  final bool isBestReply;

  const ReplyCard({
    super.key,
    required this.reply,
    this.isBestReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBestReply
            ? isDark
                ? AppColors.primaryGreen.withOpacity(0.08)
                : AppColors.primaryGreen.withOpacity(0.05)
            : isDark
                ? DarkColors.card
                : LightColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isBestReply
              ? AppColors.primaryGreen.withOpacity(0.3)
              : isDark
                  ? DarkColors.divider
                  : LightColors.divider,
          width: isBestReply ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Pharmacy icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isBestReply
                      ? const LinearGradient(
                          colors: [AppColors.primaryGreen, Color(0xFF34D399)])
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reply.pharmacyName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isBestReply
                                  ? AppColors.primaryGreen
                                  : isDark
                                      ? DarkColors.textPrimary
                                      : LightColors.textPrimary,
                            ),
                          ),
                        ),
                        if (reply.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reply.timeAgo,
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
            ],
          ),
          const SizedBox(height: 10),
          // Reply content
          Text(
            reply.content,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? DarkColors.textSecondary
                  : LightColors.textSecondary,
              height: 1.5,
            ),
          ),
          // Medicine info
          if (reply.medicineName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? DarkColors.surfaceVariant
                    : LightColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medication_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF90CAF9)
                        : AppColors.primaryBlue,
                  ),
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
                            color: isDark
                                ? DarkColors.textPrimary
                                : LightColors.textPrimary,
                          ),
                        ),
                        Text(
                          reply.isAvailable ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: reply.isAvailable
                                ? AppColors.primaryGreen
                                : AppColors.accentRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reply.price != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
            ),
          ],
          const SizedBox(height: 10),
          // Actions
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  backgroundColor: isBestReply
                      ? AppColors.primaryGreen.withOpacity(0.1)
                      : isDark
                          ? AppColors.primaryGreen.withOpacity(0.08)
                          : AppColors.primaryGreen.withOpacity(0.06),
                ),
                icon: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
                label: Text(
                  'Best Reply',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: Icon(
                  Icons.chat_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue,
                ),
                label: Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
