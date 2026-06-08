// ignore_for_file: deprecated_member_use, dead_code

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Elaaj/core/models/pharmacy_model.dart';
import 'package:Elaaj/core/network/api_endpoints.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/pharmacies/view/pharmacy_details_screen.dart';
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
          _buildHeader(context, showBestReplyHighlight, isDark),
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

  Future<void> _navigateToPharmacyDetails(BuildContext context, String pharmacyId, String pharmacyName) async {
    if (pharmacyId.isEmpty && pharmacyName.isEmpty) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.card : LightColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark ? DarkColors.divider : LightColors.divider,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: Text(
                  'جاري تحميل تفاصيل الصيدلية...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final api = ApiEndpoints();
      PharmacyModel? pharmacy;
      
      if (pharmacyId.isNotEmpty) {
        final response = await api.getPharmacyById(id: pharmacyId);
        pharmacy = PharmacyModel.fromJson(response);
      } else {
        // Fallback: Search for pharmacy by name
        final results = await api.searchPharmacies(keyword: pharmacyName);
        if (results.isNotEmpty) {
          pharmacy = PharmacyModel.fromJson(results.first as Map<String, dynamic>);
        }
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        if (pharmacy != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PharmacyDetailsScreen(pharmacy: pharmacy!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر العثور على تفاصيل هذه الصيدلية',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحميل تفاصيل الصيدلية: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildHeader(BuildContext context, bool isBest, bool isDark) {
    final isPharmacyNameArabic = _isArabic(reply.pharmacyName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToPharmacyDetails(context, reply.pharmacyId, reply.pharmacyName),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: Row(
            textDirection: isPharmacyNameArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              _buildAvatar(isBest),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: isPharmacyNameArabic 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                  children: [
                    _buildNameRow(isBest, isDark),
                    const SizedBox(height: 2),
                    Text(
                      reply.timeAgo,
                      textDirection: isPharmacyNameArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? DarkColors.textHint : LightColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    final isPharmacyNameArabic = _isArabic(reply.pharmacyName);

    return Row(
      textDirection: isPharmacyNameArabic ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Expanded(
          child: Text(
            reply.pharmacyName,
            textDirection: isPharmacyNameArabic ? TextDirection.rtl : TextDirection.ltr,
            textAlign: isPharmacyNameArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: nameColor,
              fontFamily: isPharmacyNameArabic ? 'Cairo' : null,
            ),
          ),
        ),
        if (reply.isVerified) const _VerifiedBadge(),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    final isArabicText = _isArabic(reply.content);
    return SizedBox(
      width: double.infinity,
      child: Text(
        reply.content,
        textDirection: isArabicText ? TextDirection.rtl : TextDirection.ltr,
        textAlign: isArabicText ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
          height: 1.5,
          fontFamily: isArabicText ? 'Cairo' : null,
        ),
      ),
    );
  }

  Widget _buildMedicineInfo(bool isDark) {
    final iconColor = isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue;
    final surfaceColor = isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant;
    final isMedicineArabic = reply.medicineName != null && _isArabic(reply.medicineName!);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        textDirection: isMedicineArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Icon(Icons.medication_rounded, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: isMedicineArabic 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  reply.medicineName!,
                  textDirection: isMedicineArabic ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isMedicineArabic ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                    fontFamily: isMedicineArabic ? 'Cairo' : null,
                  ),
                ),
                Text(
                  reply.isAvailable ? 'In Stock' : 'Out of Stock',
                  textDirection: isMedicineArabic ? TextDirection.rtl : TextDirection.ltr,
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

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
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
