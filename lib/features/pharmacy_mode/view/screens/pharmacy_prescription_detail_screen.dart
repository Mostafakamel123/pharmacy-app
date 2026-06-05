// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Elaaj/core/config/env_config.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_request_providers.dart';

/// Pharmacy Prescription Detail Screen
/// 
/// Allows pharmacies to inspect a prescription image with pinch-to-zoom (InteractiveViewer),
/// see details (patient notes, distance, etc.), and either reject it or submit a price offer.
class PharmacyPrescriptionDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> prescription;
  final dynamic pharmacy;

  const PharmacyPrescriptionDetailScreen({
    super.key,
    required this.prescription,
    required this.pharmacy,
  });

  @override
  ConsumerState<PharmacyPrescriptionDetailScreen> createState() =>
      _PharmacyPrescriptionDetailScreenState();
}

class _PharmacyPrescriptionDetailScreenState
    extends ConsumerState<PharmacyPrescriptionDetailScreen> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isAvailable = true;
  bool _isSubmitting = false;

  final List<String> _arabicPresets = [
    'العلاج متوفر بالكامل وجاهز للشحن فوراً',
    'العلاج متوفر حالياً والتوصيل مجاناً خلال 30 دقيقة',
    'متوفر جميع الأصناف ما عدا صنف واحد (تواصل لمزيد من التفاصيل)',
    'متوفر بديل للأنواع غير المتوفرة بنفس الفعالية',
  ];

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${EnvConfig.apiBaseUrl}$path';
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Prescription Zoom / تكبير الروشتة',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: InteractiveViewer(
                maxScale: 6.0,
                minScale: 1.0,
                child: Hero(
                  tag: 'prescription_image_hero',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, size: 64, color: AppColors.accentRed),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Failed to load image / فشل تحميل الصورة',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Prescription information
    final String id = widget.prescription['id'] as String? ?? '';
    final String displayId = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase();
    final String notes = widget.prescription['notes'] as String? ?? 'No notes provided / لا توجد ملاحظات';
    final String imageUrl = widget.prescription['imageUrl'] as String? ?? '';
    final double distance = (widget.prescription['distance'] as num?)?.toDouble() ?? 0.0;
    final int statusVal = widget.prescription['status'] as int? ?? 0;

    // Listen to local pharmacy state to see if they already submitted an offer/reply
    final localState = ref.watch(pharmacyPrescriptionsLocalProvider(widget.pharmacy.id));
    final localOffer = localState.offeredDetails[id];
    final isRejected = localState.rejectedIds.contains(id);

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      appBar: AppBar(
        title: Text('Prescription #$displayId'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status Indicator & Info Summary
            _buildSummaryHeader(isDark, displayId, distance, statusVal, localOffer, isRejected),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Patient Notes Section
                  _buildPatientNotesSection(isDark, notes),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Interactive Prescription Image Section
                  _buildPrescriptionImageSection(isDark, imageUrl),
                  const SizedBox(height: AppSpacing.xl),

                  // 4. Offer Form or Details Section
                  if (isRejected)
                    _buildRejectedIndicator(isDark)
                  else if (localOffer != null)
                    _buildSubmittedOfferCard(isDark, localOffer, statusVal, id)
                  else
                    _buildOfferForm(isDark, id),
                  
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(
    bool isDark,
    String displayId,
    double distance,
    int statusVal,
    Map<String, dynamic>? localOffer,
    bool isRejected,
  ) {
    String statusStr = 'Pending Response';
    Color statusColor = AppColors.accentYellow;

    if (isRejected) {
      statusStr = 'Rejected';
      statusColor = AppColors.accentRed;
    } else if (statusVal == 2) {
      statusStr = 'Preparing (Accepted)';
      statusColor = AppColors.primaryBlue;
    } else if (statusVal == 3) {
      statusStr = 'Ready (Completed)';
      statusColor = AppColors.primaryGreen;
    } else if (localOffer != null) {
      statusStr = 'Offer Submitted';
      statusColor = AppColors.primaryGreen;
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request from Patient #$displayId',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        '${distance.toStringAsFixed(2)} km away',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
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
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: statusColor.withOpacity(0.24)),
            ),
            child: Text(
              statusStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientNotesSection(bool isDark, String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.primaryBlue.withOpacity(0.08) 
            : AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.comment_rounded,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Patient Notes / ملاحظات المريض',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            notes,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionImageSection(bool isDark, String imageUrlStr) {
    final String fullUrl = _getFullImageUrl(imageUrlStr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Prescription Image / صورة الروشتة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 14,
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'Pinch to zoom / اسحب للتكبير',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? DarkColors.surface : LightColors.surface,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: fullUrl.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: AppSpacing.sm),
                        Text('No Image Uploaded', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () => _showFullScreenImage(context, fullUrl),
                    child: InteractiveViewer(
                      maxScale: 5.0,
                      minScale: 1.0,
                      child: Hero(
                        tag: 'prescription_image_hero',
                        child: Image.network(
                          fullUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined, size: 48, color: AppColors.accentRed),
                                  SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Error loading image\nفشل تحميل الصورة',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.accentRed, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferForm(bool isDark, String prescriptionId) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Submit Price Offer / إرسال العرض',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
            ),
          ),
          const Divider(height: AppSpacing.lg),
          
          // 1. Price Input
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Total Price (EGP) / السعر الإجمالي (جنيه)',
              hintText: 'e.g. 150',
              prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primaryGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Custom Message Input
          TextField(
            controller: _messageController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Offer Notes / الرسالة المرفقة للمريض',
              hintText: 'e.g. Fully available, fast delivery',
              prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Presets Header
          Text(
            'Quick Presets / ردود سريعة باللغة العربية:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Presets Chips
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: _arabicPresets.map((preset) {
              return ActionChip(
                label: Text(
                  preset.length > 30 ? '${preset.substring(0, 30)}...' : preset,
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                padding: const EdgeInsets.all(AppSpacing.xxs),
                onPressed: () {
                  setState(() {
                    _messageController.text = preset;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Availability Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 20,
                      color: _isAvailable ? AppColors.primaryGreen : Colors.grey,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'All items are available / جميع الأصناف متوفرة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch(
                value: _isAvailable,
                activeColor: AppColors.primaryGreen,
                onChanged: (val) {
                  setState(() {
                    _isAvailable = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Action Buttons
          Row(
            children: [
              // Reject Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting 
                      ? null 
                      : () async {
                          setState(() => _isSubmitting = true);
                          
                          // Call backend API to change status to 4 (Rejected/Declined)
                          final success = await ref.read(pharmacyActionsProvider).changeStatus(
                            prescriptionId: prescriptionId,
                            status: 4,
                          );

                          await ref.read(pharmacyPrescriptionsLocalProvider(widget.pharmacy.id).notifier)
                              .rejectPrescription(prescriptionId);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                    ? 'Request Rejected / تم رفض الطلب بنجاح' 
                                    : 'Rejected locally / تم الرفض محلياً'),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject / رفض'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentRed,
                    side: const BorderSide(color: AppColors.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Submit Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final double price = double.tryParse(_priceController.text) ?? 0.0;
                          final String message = _messageController.text;

                          if (price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid price / يرجى إدخال سعر صحيح')),
                            );
                            return;
                          }

                          setState(() => _isSubmitting = true);

                          final success = await ref.read(pharmacyActionsProvider).submitReply(
                            prescriptionId: prescriptionId,
                            pharmacyId: widget.pharmacy.id,
                            message: message.isEmpty ? 'العلاج متوفر وجاهز للشحن' : message,
                            totalPrice: price,
                            isAvailable: _isAvailable,
                          );

                          setState(() => _isSubmitting = false);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                    ? 'Offer submitted successfully / تم إرسال العرض بنجاح' 
                                    : 'Error submitting offer / حدث خطأ أثناء إرسال العرض'),
                              ),
                            );
                            if (success) {
                              Navigator.pop(context);
                            }
                          }
                        },
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Send Offer / إرسال'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.accentRed.withOpacity(0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.accentRed, size: 24),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejected Locally',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentRed),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'You rejected this prescription request. It has been hidden from your active orders.',
                  style: TextStyle(fontSize: 12, color: AppColors.accentRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedOfferCard(bool isDark, Map<String, dynamic> offer, int statusVal, String prescriptionId) {
    final double price = (offer['price'] as num?)?.toDouble() ?? 0.0;
    final String message = offer['message'] as String? ?? '';
    final bool available = offer['isAvailable'] as bool? ?? true;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Offer Header
          Row(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Your Offer Details / تفاصيل عرضك المالي',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),

          // Pricing block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Offered / عرض السعر:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                '${price.toStringAsFixed(2)} EGP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Message block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Message / الرسالة:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Availability
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Availability / التوفر:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                available ? 'All items available / متوفر بالكامل' : 'Some items missing / غير متوفر بالكامل',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: available ? AppColors.primaryGreen : AppColors.accentYellow,
                ),
              ),
            ],
          ),
          
          if (statusVal == 2) ...[
            const Divider(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.celebration_rounded, color: AppColors.primaryBlue, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Patient accepted this offer! Start preparing the order.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final String chatId = 'chat_historical_$prescriptionId';
                  context.push('/chat/$chatId', extra: 'Customer / زبون');
                },
                icon: const Icon(Icons.chat_rounded, size: 20),
                label: const Text('Chat with Patient / المحادثة مع المريض', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await ref.read(pharmacyActionsProvider).changeStatus(
                    prescriptionId: prescriptionId,
                    status: 3,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                            ? 'Order marked as ready / تم تجهيز الطلب بنجاح' 
                            : 'Error updating order / حدث خطأ أثناء التحديث'),
                      ),
                    );
                    if (success) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(Icons.delivery_dining_rounded, size: 20),
                label: const Text('Mark as Ready / Completed (تم التجهيز والتوصيل)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
