// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:Elaaj/core/config/env_config.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/core/routing/app_routes.dart';
import 'package:Elaaj/core/network/api_endpoints.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/chat/controller/chat_providers.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_request_providers.dart';
import 'package:Elaaj/features/pharmacy_mode/view/screens/pharmacy_prescription_detail_screen.dart';

/// Pharmacy Accepted Prescriptions Screen
/// 
/// Displays the list of prescriptions that the pharmacy has accepted
/// and the user approved. Allows starting/continuing chat with the patient
/// and viewing details.
class PharmacyAcceptedPrescriptionsScreen extends ConsumerWidget {
  const PharmacyAcceptedPrescriptionsScreen({super.key});

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
                'Prescription Preview / عرض الروشتة',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: InteractiveViewer(
                maxScale: 6.0,
                minScale: 1.0,
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
                      child: Icon(Icons.broken_image_outlined, size: 64, color: AppColors.accentRed),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleChatNavigation(
    BuildContext context,
    WidgetRef ref,
    String prescriptionId,
    dynamic pharmacy,
    String? patientId,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    try {
      final api = ApiEndpoints();
      final presData = await api.getPrescriptionById(id: prescriptionId);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Extract replies
      final repliesRaw = presData['replies'] ?? presData['offers'] ?? presData['prescriptionReplies'] ?? [];
      final List<dynamic> fetchedReplies = repliesRaw is List ? repliesRaw : [];
      
      // Resolve patientId case-insensitively
      final String resolvedPatientId = patientId ??
                                        presData['patientId']?.toString() ?? 
                                        presData['userId']?.toString() ?? 
                                        (fetchedReplies.isNotEmpty ? fetchedReplies.first['patientId']?.toString() : null) ?? 
                                        'patient_123';

      final String resolvedPharmacyId = pharmacy.id;
      final String resolvedPharmacyName = pharmacy.name;

      // Extract details for chat info seeding
      double price = 0.0;
      String message = 'العرض المقبول';
      final acceptedReply = fetchedReplies.firstWhere((r) => r is Map, orElse: () => null);
      if (acceptedReply != null) {
        price = (acceptedReply['totalPrice'] as num?)?.toDouble() ?? 0.0;
        message = acceptedReply['message']?.toString() ?? 'العلاج متوفر وجاهز للشحن';
      }

      // Seed the chat room dynamically!
      final String resolvedChatId = 'chat_historical_$prescriptionId';
      ref.read(chatsProvider.notifier).createPrescriptionChat(
        chatId: resolvedChatId,
        pharmacyId: resolvedPharmacyId,
        pharmacyName: resolvedPharmacyName,
        price: price,
        message: message,
        prescriptionId: prescriptionId,
        prescriptionImage: presData['imageUrl']?.toString(),
        prescriptionNotes: presData['notes']?.toString(),
      );

      // Resolve patient name
      String patientName = 'Patient / مريض';
      if (presData.containsKey('patientName') && presData['patientName'] != null) {
        patientName = presData['patientName'].toString();
      } else if (presData.containsKey('userName') && presData['userName'] != null) {
        patientName = presData['userName'].toString();
      } else if (presData.containsKey('fullName') && presData['fullName'] != null) {
        patientName = presData['fullName'].toString();
      } else {
        final patientReply = fetchedReplies.firstWhere(
          (r) => r is Map && r['senderId']?.toString() == resolvedPatientId && r['senderName'] != null,
          orElse: () => null,
        );
        if (patientReply != null) {
          patientName = patientReply['senderName'].toString();
        } else {
          final nonPharmacyReply = fetchedReplies.firstWhere(
            (r) => r is Map && r['senderId']?.toString() != resolvedPharmacyId && r['senderName'] != null,
            orElse: () => null,
          );
          if (nonPharmacyReply != null) {
            patientName = nonPharmacyReply['senderName'].toString();
          }
        }
      }

      if (context.mounted) {
        context.push(
          AppRoutes.prescriptionChat,
          extra: {
            'prescriptionId': prescriptionId,
            'otherUserId': resolvedPatientId,
            'currentUserId': ref.read(authProvider).user?.id ?? '',
            'isPharmacy': true,
            'pharmacyId': resolvedPharmacyId,
            'otherUserName': patientName,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chat details: $e / فشل تحميل تفاصيل المحادثة: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final pharmacyState = ref.watch(pharmacyModeProvider);
    final currentPharmacy = pharmacyState.currentPharmacy;

    if (currentPharmacy == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accepted Prescriptions / الروشتات المقبولة'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 80,
                  color: isDark ? DarkColors.textHint : LightColors.textHint,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Pharmacy Selected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select a pharmacy from the drawer to view accepted prescriptions',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final acceptedAsync = ref.watch(pharmacyAcceptedPrescriptionsProvider(currentPharmacy.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Prescriptions / الروشتات المقبولة'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pharmacyAcceptedPrescriptionsProvider(currentPharmacy.id));
        },
        child: acceptedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.accentRed),
                const SizedBox(height: 16),
                Text('Error loading: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(pharmacyAcceptedPrescriptionsProvider(currentPharmacy.id));
                  },
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
          data: (presList) {
            final activeList = presList.where((p) {
              final statusVal = p['status'] as int? ?? 2;
              return statusVal == 2; // only preparing (accepted) status
            }).toList();

            if (activeList.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: isDark ? DarkColors.textHint : LightColors.textHint,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Accepted Prescriptions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prescriptions accepted by you and approved by patients will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: activeList.length,
              itemBuilder: (context, index) {
                final item = activeList[index];
                final String id = item['id'] as String? ?? '';
                final String notes = item['notes'] as String? ?? 'Prescription Request';
                final String displayId = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase();
                final String imageUrlStr = item['imageUrl'] as String? ?? '';
                final String fullImageUrl = _getFullImageUrl(imageUrlStr);
                final String createdAtStr = item['createdAt'] as String? ?? '';
                
                String timeText = '';
                if (createdAtStr.isNotEmpty) {
                  final dt = DateTime.tryParse(createdAtStr);
                  if (dt != null) {
                    timeText = DateFormat('MMM d, y • hh:mm a').format(dt.toLocal());
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? DarkColors.surface : LightColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Prescription #$displayId',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: const Text(
                              'Preparing / جاري التجهيز',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      
                      // Notes & Image Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fullImageUrl.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () => _showFullScreenImage(context, fullImageUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: Image.network(
                                  fullImageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 64,
                                    height: 64,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, size: 24),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notes,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (timeText.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    timeText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? DarkColors.textHint : LightColors.textHint,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.lg),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PharmacyPrescriptionDetailScreen(
                                      prescription: item,
                                      pharmacy: currentPharmacy,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('Details / التفاصيل'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(color: AppColors.primaryBlue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final String? pId = item['userId']?.toString() ?? item['patientId']?.toString();
                                _handleChatNavigation(context, ref, id, currentPharmacy, pId);
                              },
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: const Text('Chat / المحادثة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
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
              },
            );
          },
        ),
      ),
    );
  }
}
