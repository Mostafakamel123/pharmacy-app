// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/core/routing/app_routes.dart';
import 'package:Elaaj/core/config/env_config.dart';
import 'package:Elaaj/features/prescription/controller/patient_prescription_providers.dart';
import 'package:Elaaj/features/prescription/controller/prescription_providers.dart';
import 'package:Elaaj/features/prescription/model/prescription_model.dart';
import 'package:Elaaj/features/prescription/model/routing_state_model.dart';
import 'package:Elaaj/features/chat/controller/chat_providers.dart';

class MyPrescriptionsScreen extends ConsumerWidget {
  const MyPrescriptionsScreen({super.key});

  dynamic _getVal(dynamic map, String key) {
    if (map is! Map) return null;
    final target = key.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key.toString().toLowerCase() == target) {
        return entry.value;
      }
    }
    return null;
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Recent / حديث';
    try {
      final parsed = DateTime.parse(isoString).toLocal();
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year;
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$day-$month-$year $hour:$minute';
    } catch (_) {
      return isoString.split('T').first;
    }
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${EnvConfig.apiBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider);

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      appBar: AppBar(
        title: const Text('My Prescriptions / طلبات الروشتة'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () async {
          ref.invalidate(patientPrescriptionsProvider);
        },
        child: prescriptionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.accentRed),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading prescription history / فشل تحميل الطلبات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('$err', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(patientPrescriptionsProvider),
                    child: const Text('Retry / إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                if (item is! Map) return const SizedBox.shrink();

                final id = _getVal(item, 'id')?.toString() ?? '';
                final displayId = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase();
                final notes = _getVal(item, 'notes')?.toString() ?? 'No notes / لا توجد ملاحظات';
                final imageUrl = _getVal(item, 'imageUrl')?.toString();
                final createdAtStr = _getVal(item, 'createdAt')?.toString();
                
                final rawStatus = _getVal(item, 'status');
                final statusVal = (rawStatus is num) ? rawStatus.toInt() : 0;
                
                final repliesRaw = _getVal(item, 'replies');
                final List<dynamic> replies = repliesRaw is List ? repliesRaw : [];

                return _buildPrescriptionCard(
                  context: context,
                  ref: ref,
                  item: item,
                  id: id,
                  displayId: displayId,
                  notes: notes,
                  imageUrl: imageUrl,
                  createdAtStr: createdAtStr,
                  statusVal: statusVal,
                  replies: replies,
                  isDark: isDark,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.uploadPrescription),
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: const Text('Upload Rx / ارفع روشتة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSec = isDark ? DarkColors.textSecondary : LightColors.textSecondary;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 96,
                color: isDark ? DarkColors.textHint : LightColors.textHint,
              ),
              const SizedBox(height: 24),
              const Text(
                'No prescriptions uploaded yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'لم يتم رفع أي روشتات بعد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload your medical prescription to receive custom offers from pharmacies nearby',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSec, height: 1.4),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.uploadPrescription),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload Prescription Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard({
    required BuildContext context,
    required WidgetRef ref,
    required Map<dynamic, dynamic> item,
    required String id,
    required String displayId,
    required String notes,
    required String? imageUrl,
    required String? createdAtStr,
    required int statusVal,
    required List<dynamic> replies,
    required bool isDark,
  }) {
    final surfaceColor = isDark ? DarkColors.surface : LightColors.surface;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final dividerColor = isDark ? DarkColors.divider : LightColors.divider;

    // Resolve Status Badge styling
    String statusTextEn = 'Active / Searching';
    String statusTextAr = 'جاري البحث';
    Color badgeColor = AppColors.primaryBlue;

    switch (statusVal) {
      case 0:
        statusTextEn = 'Searching';
        statusTextAr = 'جاري البحث عن صيدليات';
        badgeColor = AppColors.primaryBlue;
        break;
      case 1:
        statusTextEn = 'Offers Received';
        statusTextAr = 'تم استلام عروض سعر';
        badgeColor = AppColors.primaryGreen;
        break;
      case 2:
        statusTextEn = 'Preparing';
        statusTextAr = 'تم القبول وجاري التجهيز';
        badgeColor = AppColors.accentYellow;
        break;
      case 3:
        statusTextEn = 'Completed';
        statusTextAr = 'تم التجهيز والتسليم';
        badgeColor = AppColors.primaryGreen;
        break;
      case 4:
        statusTextEn = 'Declined';
        statusTextAr = 'تم رفض الطلب';
        badgeColor = AppColors.accentRed;
        break;
      case 5:
        statusTextEn = 'Cancelled';
        statusTextAr = 'تم إلغاء الطلب';
        badgeColor = AppColors.accentRed;
        break;
    }

    return Card(
      color: surfaceColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Open details on search screen by setting routing state
          _openSearchingScreen(ref, context, item, id, statusVal, replies);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Block: Rx ID and status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primaryBlue,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prescription #$displayId',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withOpacity(0.24)),
                    ),
                    child: Text(
                      isLocalArabic(context) ? statusTextAr : statusTextEn,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: dividerColor),
              const SizedBox(height: 12),

              // Content Block: Thumbnail and Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              _getFullImageUrl(imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey);
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                              },
                            )
                          : const Icon(Icons.description_rounded, size: 24, color: AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Notes and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notes,
                          style: TextStyle(
                            fontSize: 12,
                            color: textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(createdAtStr),
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Block: Offers Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        replies.isNotEmpty
                            ? '${replies.length} Offer(s) Received / ${replies.length} عرض مستلم'
                            : 'No offers yet / لا توجد عروض حالياً',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: replies.isNotEmpty ? AppColors.primaryGreen : textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isLocalArabic(BuildContext context) {
    return Localizations.maybeLocaleOf(context)?.languageCode == 'ar' || true; // Set true since user language is Arabic
  }

  void _openSearchingScreen(
    WidgetRef ref,
    BuildContext context,
    Map<dynamic, dynamic> item,
    String id,
    int statusVal,
    List<dynamic> replies,
  ) {
    // 1. Reconstruct the PrescriptionModel
    final prescription = PrescriptionModel(
      id: id,
      patientId: _getVal(item, 'patientId')?.toString() ?? 'patient_123',
      imageUrl: _getVal(item, 'imageUrl')?.toString(),
      textContent: _getVal(item, 'notes')?.toString(),
      description: _getVal(item, 'notes')?.toString(),
      createdAt: DateTime.tryParse(_getVal(item, 'createdAt')?.toString() ?? '') ?? DateTime.now(),
      isImage: _getVal(item, 'imageUrl') != null,
    );

    // 2. Map status value to RoutingStatus
    RoutingStatus rStatus = RoutingStatus.searching;
    if (replies.isNotEmpty && statusVal == 1) {
      rStatus = RoutingStatus.searching; // Searching will automatically view offers dashboard
    } else if (statusVal == 2 || statusVal == 3) {
      rStatus = RoutingStatus.pharmacyResponded;
    } else if (statusVal == 4 || statusVal == 5) {
      rStatus = RoutingStatus.allPharmaciesFailed;
    }

    // Lookup lock pharmacy details if accepted
    String? lockPharmId;
    String? chatId;
    if (statusVal == 2 || statusVal == 3) {
      final matchingReply = replies.firstWhere((r) => true, orElse: () => null);
      if (matchingReply != null) {
        lockPharmId = _getVal(matchingReply, 'pharmacyId')?.toString();
        chatId = 'chat_historical_$id';
        
        final pharmName = _getVal(matchingReply, 'pharmacyName')?.toString() ?? 'Nearby Pharmacy / صيدلية قريبة';
        final price = (_getVal(matchingReply, 'totalPrice') as num?)?.toDouble() ?? 0.0;
        final msg = _getVal(matchingReply, 'message')?.toString() ?? '';
        
        // Seed the chat room dynamically!
        ref.read(chatsProvider.notifier).createPrescriptionChat(
              chatId: chatId,
              pharmacyId: lockPharmId ?? '',
              pharmacyName: pharmName,
              price: price,
              message: msg,
              prescriptionId: id,
              prescriptionImage: _getVal(item, 'imageUrl')?.toString(),
              prescriptionNotes: _getVal(item, 'notes')?.toString(),
            );
      }
    }

    // 3. Initialize the routing notifier state
    ref.read(routingStateNotifierProvider.notifier).updateState(RoutingStateModel(
      id: id,
      patientId: prescription.patientId,
      prescription: prescription,
      status: rStatus,
      nearbyPharmacies: [],
      createdAt: prescription.createdAt,
      isRequestPending: true, // Mark active so search triggers correctly
      lockPharmacyId: lockPharmId,
      chatId: chatId,
    ));

    // 4. Force refresh single prescription to load live replies from backend
    ref.invalidate(singlePrescriptionProvider(id));
    ref.invalidate(patientPrescriptionsProvider);

    // 5. Navigate to searching screen
    context.push(AppRoutes.searchingPharmacies);
  }
}
