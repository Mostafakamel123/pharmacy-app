// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/core/routing/app_routes.dart';
import 'package:Elaaj/core/config/env_config.dart';
import 'package:Elaaj/features/prescription/controller/patient_prescription_providers.dart';
import 'package:Elaaj/features/prescription/controller/prescription_providers.dart';
import 'package:Elaaj/features/prescription/model/prescription.dart';
import 'package:Elaaj/features/prescription/model/prescription_model.dart';
import 'package:Elaaj/features/prescription/model/routing_state_model.dart';
import 'package:Elaaj/features/chat/controller/chat_providers.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/core/network/api_endpoints.dart';

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

  String _formatDate(DateTime date) {
    try {
      final parsed = date.toLocal();
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year;
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$day-$month-$year $hour:$minute';
    } catch (_) {
      return date.toIso8601String().split('T').first;
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
    final prescriptionsAsync = ref.watch(myPrescriptionsProvider);

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      appBar: AppBar(
        title: const Text('My Prescriptions / روشتاتي'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () async {
          ref.invalidate(myPrescriptionsProvider);
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
                    onPressed: () => ref.invalidate(myPrescriptionsProvider),
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
                return _buildPrescriptionCard(
                  context: context,
                  ref: ref,
                  item: item,
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
    required Prescription item,
    required bool isDark,
  }) {
    final surfaceColor = isDark ? DarkColors.surface : LightColors.surface;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final dividerColor = isDark ? DarkColors.divider : LightColors.divider;

    final id = item.id;
    final displayId = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase();
    final notes = item.notes ?? 'No notes / لا توجد ملاحظات';
    final imageUrl = item.imageUrl;
    final replies = item.replies;

    // Resolve Status Badge styling
    String statusTextEn = 'Searching';
    String statusTextAr = 'جاري البحث';
    Color badgeColor = AppColors.primaryBlue;

    switch (item.status) {
      case 0:
        statusTextEn = 'Searching';
        statusTextAr = 'جاري البحث';
        badgeColor = AppColors.primaryBlue;
        break;
      case 1:
        statusTextEn = 'Offers Available';
        statusTextAr = 'عروض متاحة';
        badgeColor = Colors.orange;
        break;
      case 2:
        statusTextEn = 'Preparing';
        statusTextAr = 'جاري التجهيز';
        badgeColor = AppColors.primaryGreen;
        break;
      case 3:
        statusTextEn = 'Completed';
        statusTextAr = 'مكتمل';
        badgeColor = Colors.grey;
        break;
      case 4:
        statusTextEn = 'Declined';
        statusTextAr = 'مرفوض';
        badgeColor = AppColors.accentRed;
        break;
      case 5:
        statusTextEn = 'Cancelled';
        statusTextAr = 'ملغي';
        badgeColor = Colors.grey;
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
          _openSearchingScreen(ref, context, item);
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
                              _formatDate(item.createdAt),
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

              // Action Block: Offers Summary + Open Chat
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

                  // ── Open Chat Button (only when status == 2) ──────────────
                  if (item.status == 2) ...[  
                    const SizedBox(height: 10),
                    Builder(
                      builder: (ctx) {
                        final authState = ref.read(authProvider);
                        final isPharmacy = ref.read(isPharmacyModeProvider);
                        final pharmacyMode = ref.read(pharmacyModeProvider);
                        final currentUserId = authState.user?.id ?? '';

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Show progress indicator dialog
                              showDialog(
                                context: ctx,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                final api = ApiEndpoints();
                                final presData = await api.getPrescriptionById(id: id);
                                
                                // Close the progress dialog
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                }

                                final repliesRaw = presData['replies'] ?? presData['offers'] ?? presData['prescriptionReplies'] ?? [];
                                final List<dynamic> fetchedReplies = repliesRaw is List ? repliesRaw : [];
                                final firstReply = fetchedReplies.firstWhere(
                                  (r) => r is Map && _getVal(r, 'pharmacyId') != null,
                                  orElse: () => null,
                                );

                                if (firstReply == null) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('No pharmacy reply found for this prescription. / لم يتم العثور على رد من الصيدلية لهذه الروشتة.'),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final resolvedPharmacyId = _getVal(firstReply, 'pharmacyId')?.toString() ?? '';
                                final resolvedPharmacyName = _getVal(firstReply, 'pharmacyName')?.toString() ?? 'Pharmacy';
                                final resolvedPrice = (_getVal(firstReply, 'totalPrice') as num?)?.toDouble() ?? 0.0;
                                final resolvedMsg = _getVal(firstReply, 'message')?.toString() ?? '';

                                final String targetOtherUserId;
                                final String targetOtherUserName;
                                final String? targetPharmacyIdParam;

                                if (isPharmacy) {
                                  targetOtherUserId = _getVal(firstReply, 'patientId')?.toString() ?? 'patient_123';
                                  targetOtherUserName = 'Patient';
                                  targetPharmacyIdParam = pharmacyMode.currentPharmacy?.id ?? resolvedPharmacyId;
                                } else {
                                  targetOtherUserId = resolvedPharmacyId;
                                  targetOtherUserName = resolvedPharmacyName;
                                  targetPharmacyIdParam = null;
                                }

                                if (targetOtherUserId.isEmpty) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cannot open chat: Other user ID is empty. / لا يمكن فتح المحادثة: معرف الطرف الآخر فارغ.'),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                // Seed the chat room dynamically!
                                final String resolvedChatId = 'chat_historical_$id';
                                ref.read(chatsProvider.notifier).createPrescriptionChat(
                                  chatId: resolvedChatId,
                                  pharmacyId: resolvedPharmacyId,
                                  pharmacyName: resolvedPharmacyName,
                                  price: resolvedPrice,
                                  message: resolvedMsg,
                                  prescriptionId: id,
                                  prescriptionImage: item.imageUrl,
                                  prescriptionNotes: item.notes,
                                );

                                if (ctx.mounted) {
                                  context.push(
                                    AppRoutes.prescriptionChat,
                                    extra: {
                                      'prescriptionId': id,
                                      'otherUserId': targetOtherUserId,
                                      'currentUserId': currentUserId,
                                      'isPharmacy': isPharmacy,
                                      'pharmacyId': targetPharmacyIdParam,
                                      'otherUserName': targetOtherUserName,
                                    },
                                  );
                                }
                              } catch (e) {
                                // Close the progress dialog if open
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to load chat details: $e / فشل تحميل تفاصيل المحادثة: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.chat_rounded, size: 16),
                            label: const Text(
                              'Open Chat / فتح المحادثة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
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
    Prescription item,
  ) {
    final authState = ref.read(authProvider);
    final patientId = authState.user?.id ?? 'patient_123';

    // 1. Reconstruct the PrescriptionModel
    final prescription = PrescriptionModel(
      id: item.id,
      patientId: patientId,
      imageUrl: item.imageUrl,
      textContent: item.notes,
      description: item.notes,
      createdAt: item.createdAt,
      isImage: item.imageUrl != null,
    );

    // 2. Map status value to RoutingStatus
    RoutingStatus rStatus = RoutingStatus.searching;
    if (item.replies.isNotEmpty && item.status == 1) {
      rStatus = RoutingStatus.searching; // Searching will automatically view offers dashboard
    } else if (item.status == 2 || item.status == 3) {
      rStatus = RoutingStatus.pharmacyResponded;
    } else if (item.status == 4 || item.status == 5) {
      rStatus = RoutingStatus.allPharmaciesFailed;
    }

    // Lookup lock pharmacy details if accepted
    String? lockPharmId;
    String? chatId;
    if (item.status == 2 || item.status == 3) {
      final matchingReply = item.replies.firstWhere((r) => true, orElse: () => null);
      if (matchingReply != null) {
        lockPharmId = _getVal(matchingReply, 'pharmacyId')?.toString();
        chatId = 'chat_historical_${item.id}';
        
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
              prescriptionId: item.id,
              prescriptionImage: item.imageUrl,
              prescriptionNotes: item.notes,
            );
      }
    }

    // 3. Initialize the routing notifier state
    ref.read(routingStateNotifierProvider.notifier).updateState(RoutingStateModel(
      id: item.id,
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
    ref.invalidate(singlePrescriptionProvider(item.id));
    ref.invalidate(myPrescriptionsProvider);

    // 5. Navigate to searching screen
    context.push(AppRoutes.searchingPharmacies);
  }
}
