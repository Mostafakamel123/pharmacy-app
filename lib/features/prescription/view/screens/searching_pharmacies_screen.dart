// ignore_for_file: use_super_parameters, deprecated_member_use, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/core/routing/app_routes.dart';
import 'package:Elaaj/features/prescription/model/routing_state_model.dart';
import 'package:Elaaj/core/models/pharmacy_model.dart';
import 'package:Elaaj/features/prescription/controller/prescription_providers.dart';
import 'package:Elaaj/features/prescription/controller/patient_prescription_providers.dart';
import 'package:Elaaj/features/chat/controller/chat_providers.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';

/// Searching Pharmacies Screen
/// Shows animated search with countdown timer and current pharmacy being contacted
class SearchingPharmaciesScreen extends ConsumerStatefulWidget {
  const SearchingPharmaciesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchingPharmaciesScreen> createState() =>
      _SearchingPharmaciesScreenState();
}

class _SearchingPharmaciesScreenState
    extends ConsumerState<SearchingPharmaciesScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  Timer? _pollingTimer;
  String? _acceptingReplyId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Start countdown timer if not already running
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(countdownTimerNotifierProvider.notifier).start();
    });

    // Poll the patient history API and specific prescription details for incoming pharmacy replies/offers every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final routingState = ref.read(routingStateNotifierProvider);
        if (routingState != null) {
          ref.refresh(singlePrescriptionProvider(routingState.id));
        }
        ref.refresh(patientPrescriptionsProvider);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routingState = ref.watch(routingStateNotifierProvider);
    final countdown = ref.watch(countdownTimerNotifierProvider);
    final currentPharmacy = routingState?.currentPharmacy;

    if (routingState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Fetch replies/offers nested in our current prescription from dedicated single endpoint provider
    final singlePresAsync = ref.watch(singlePrescriptionProvider(routingState.id));
    dynamic currentPres = singlePresAsync.value;
    bool fetchedFromSingle = currentPres != null && currentPres is Map && currentPres.isNotEmpty;

    // Fetch replies/offers nested in our current prescription from history provider as robust fallback
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider);
    final prescriptionsList = prescriptionsAsync.value ?? [];
    
    if (!fetchedFromSingle) {
      // Completely case-insensitive matching from history
      currentPres = prescriptionsList.firstWhere(
        (p) {
          if (p is! Map) return false;
          final id = _getVal(p, 'id')?.toString().toLowerCase();
          final pId = _getVal(p, 'prescriptionId')?.toString().toLowerCase();
          final targetId = routingState.id.toLowerCase();
          return id == targetId || pId == targetId;
        },
        orElse: () => null,
      );
    }

    // Completely case-insensitive replies retrieval
    final rawReplies = currentPres != null 
        ? (_getVal(currentPres, 'replies') ?? _getVal(currentPres, 'offers') ?? _getVal(currentPres, 'prescriptionReplies') ?? _getVal(currentPres, 'Replies') ?? _getVal(currentPres, 'Offers'))
        : null;
    final List<dynamic> replies = rawReplies is List ? rawReplies : [];

    // Completely case-insensitive status retrieval
    final rawStatus = currentPres != null ? _getVal(currentPres, 'status') : null;
    final int serverStatus = (rawStatus is num) ? rawStatus.toInt() : 0;

    // ELAAJ REAL-TIME DEBUG LOGGING
    print('------------------ ELAAJ PRESCRIPTION REAL-TIME DEBUG ------------------');
    print('🎯 PATIENT TARGET PRESCRIPTION ID (routingState.id): "${routingState.id}"');
    print('📦 TOTAL PRESCRIPTIONS RECEIVED FROM API: ${prescriptionsList.length}');
    for (int i = 0; i < prescriptionsList.length; i++) {
      final p = prescriptionsList[i];
      if (p is Map) {
        final id = _getVal(p, 'id')?.toString();
        final pId = _getVal(p, 'prescriptionId')?.toString();
        final status = _getVal(p, 'status');
        print('   [$i] id: "$id" | prescriptionId: "$pId" | status: $status');
      } else {
        print('   [$i] NOT A MAP: $p');
      }
    }
    
    if (currentPres != null) {
      print('✅ MATCH FOUND IN HISTORY!');
      print('ℹ️ Data source resolved from: ${fetchedFromSingle ? "Single API endpoint (/api/Prescriptions/{id})" : "History API list (/api/Prescriptions/my-prescriptions)"}');
      print('📝 Matched Prescription JSON: $currentPres');
      print('❓ Raw replies from JSON: $rawReplies (Type: ${rawReplies?.runtimeType})');
      print('⚡ Parsed replies list length: ${replies.length}');
      print('🚨 Server status value: $serverStatus');
    } else {
      print('❌ NO MATCH FOUND FOR "${routingState.id}" IN BOTH CHANNELS!');
    }
    print('------------------------------------------------------------------------');

    // Check if pharmacy responded and we have a chat ID - trigger automatic navigation
    if (routingState.status == RoutingStatus.pharmacyResponded && routingState.chatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          String displayName = 'Pharmacy / صيدلية قريبة';
          if (routingState.lockPharmacyId != null) {
            final matchingReply = replies.firstWhere(
              (r) => _getVal(r, 'pharmacyId')?.toString() == routingState.lockPharmacyId,
              orElse: () => null,
            );
            if (matchingReply != null) {
              displayName = _getVal(matchingReply, 'pharmacyName')?.toString() ?? displayName;
            }
          }
          // Reset routing state so patient doesn't get stuck if they press back
          ref.read(routingStateNotifierProvider.notifier).resetRouting();
          
          final currentUserId = ref.read(authProvider).user?.id ?? '';
          final pharmacyId = routingState.lockPharmacyId ?? '';
          
          context.replace(
            AppRoutes.prescriptionChat,
            extra: {
              'prescriptionId': routingState.id,
              'otherUserId': pharmacyId,
              'currentUserId': currentUserId,
              'isPharmacy': false,
              'pharmacyId': null,
              'otherUserName': displayName,
            },
          );
        }
      });
    }

    // Pause countdown timer and stop animations if there are replies, then show Offers Dashboard
    if (replies.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(countdownTimerNotifierProvider.notifier).pause();
        if (_pulseController.isAnimating) _pulseController.stop();
        if (_rotateController.isAnimating) _rotateController.stop();
      });
      return _buildOffersDashboardScreen(replies, routingState, isDark);
    }

    final bool isExplicitlyRejectedOrCancelled = serverStatus == 4 || serverStatus == 5;

    // Check if all pharmacies failed or explicitly rejected
    if (routingState.status == RoutingStatus.allPharmaciesFailed || isExplicitlyRejectedOrCancelled) {
      return _buildAllPharmaciesFailedScreen(routingState, isDark, isExplicitlyRejected: isExplicitlyRejectedOrCancelled);
    }

    // Check if pharmacy responded
    if (routingState.status == RoutingStatus.pharmacyResponded) {
      return _buildPharmacyRespondedScreen(routingState, isDark, replies, serverStatus);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Searching Pharmacies'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              if (replies.isNotEmpty) ...[
                _buildOfferReceivedBanner(context, replies.length, isDark),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 20),

              // Animated Pulse Circle
              _buildPulseAnimation(),
              const SizedBox(height: 40),

              // Status Text
              Text(
                'Looking for the nearest pharmacy...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'re automatically contacting pharmacies nearby',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? DarkColors.textSecondary
                      : LightColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // Current Pharmacy Card
              if (currentPharmacy != null) ...[
                _buildCurrentPharmacyCard(currentPharmacy, context, isDark),
                const SizedBox(height: 24),
              ],

              // Timer Card
              _buildTimerCard(countdown, context, isDark),
              const SizedBox(height: 24),

              // Progress Info
              _buildProgressInfo(routingState, context, isDark),
              const SizedBox(height: 40),

              // Remaining Pharmacies
              _buildRemainingPharmacies(routingState, context, isDark),


              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(routingStateNotifierProvider.notifier)
                        .resetRouting();
                    context.pop();
                  },
                  child: const Text('Cancel Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffersDashboardScreen(List<dynamic> replies, RoutingStateModel routingState, bool isDark) {
    final surfaceColor = isDark ? DarkColors.surface : LightColors.surface;
    final textSec = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final bgColor = isDark ? DarkColors.background : LightColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Offers Received / العروض المستلمة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Success Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen.withOpacity(0.15),
                      AppColors.primaryBlue.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primaryGreen,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Offer Received! / تم استلام عرض سعر!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We found ${replies.length} nearby pharmacy offer(s) for you. Please review details below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textSec, height: 1.4),
                    ),
                    Text(
                      'تم العثور على ${replies.length} عرض سعر من الصيدليات المجاورة. يرجى مراجعة التفاصيل أدناه.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textSec, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Incoming Offers list title
              Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Available Offers / العروض المتوفرة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Offers List
              ...replies.map((reply) {
                final rawPrice = _getVal(reply, 'totalPrice');
                final double price = (rawPrice is num) ? rawPrice.toDouble() : 0.0;
                
                final rawAvailable = _getVal(reply, 'isAvailable');
                final bool available = (rawAvailable is bool) ? rawAvailable : true;
                
                final String msg = _getVal(reply, 'message')?.toString() ?? 'العلاج متوفر بالكامل وجاهز للشحن فوراً';
                final String pharmId = _getVal(reply, 'pharmacyId')?.toString() ?? '';
                final String replyId = _getVal(reply, 'id')?.toString() ?? '';
                final bool isThisAccepting = _acceptingReplyId == replyId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: surfaceColor,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.primaryBlue.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pharmacy Header & Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getVal(reply, 'pharmacyName')?.toString() ?? 'صيدلية قريبة',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      _getVal(reply, 'pharmacyName') != null ? 'Pharmacy' : 'Nearby Pharmacy',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSec,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '$price EGP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Chat bubble notes box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Text(
                            msg,
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Availability Badges
                        Row(
                          children: [
                            Icon(
                              available ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              color: available ? AppColors.primaryGreen : AppColors.accentRed,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                available
                                    ? 'All items are available / جميع الأصناف متوفرة'
                                    : 'Some items missing / بعض الأصناف غير متوفرة',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: available ? AppColors.primaryGreen : AppColors.accentRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Accept CTA
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _acceptingReplyId != null
                                ? null
                                : () async {
                                    setState(() {
                                      _acceptingReplyId = replyId;
                                    });

                                    final success = await ref.read(patientActionsProvider).acceptOffer(
                                          prescriptionId: routingState.id,
                                          replyId: replyId,
                                        );

                                    if (mounted) {
                                      setState(() {
                                        _acceptingReplyId = null;
                                      });
                                    }

                                    if (success && mounted) {
                                      final newChatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
                                      final pName = _getVal(reply, 'pharmacyName')?.toString() ?? 'Nearby Pharmacy / صيدلية قريبة';
                                      
                                      // Dynamically seed the chat session inside chatsProvider
                                      ref.read(chatsProvider.notifier).createPrescriptionChat(
                                            chatId: newChatId,
                                            pharmacyId: pharmId,
                                            pharmacyName: pName,
                                            price: price,
                                            message: msg,
                                            prescriptionId: routingState.id,
                                            prescriptionImage: routingState.prescription.imageUrl,
                                            prescriptionNotes: routingState.prescription.textContent ?? routingState.prescription.description,
                                          );

                                      // Lock locally and transition to pharmacy responded chat screen
                                      ref.read(routingStateNotifierProvider.notifier).handlePharmacyResponse(
                                            pharmId,
                                            newChatId,
                                          );
                                    }
                                  },
                            icon: isThisAccepting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.chat_rounded, size: 18),
                            label: Text(
                              isThisAccepting
                                  ? 'Connecting... / جاري الاتصال...'
                                  : 'Accept Offer & Chat / قبول وبدء المحادثة',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // 4. Cancel Request Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(routingStateNotifierProvider.notifier).resetRouting();
                    context.pop();
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Request / إلغاء طلب البحث'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentRed,
                    side: const BorderSide(color: AppColors.accentRed, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseAnimation() {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryBlue.withOpacity(0.2),
          border: Border.all(color: AppColors.primaryBlue, width: 2),
        ),
        child: Center(
          child: RotationTransition(
            turns: _rotateController,
            child: const Icon(
              Icons.location_on_rounded,
              size: 48,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPharmacyCard(
    PharmacyModel pharmacy,
    BuildContext context,
    bool isDark,
  ) {
    final textSecondary = isDark
        ? DarkColors.textSecondary
        : LightColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(isDark ? 0.5 : 1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.2),
                ),
                child: Center(
                  child: Icon(Icons.store, color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacting',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmacy.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  pharmacy.location,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${pharmacy.distance}km away',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(
                    isDark ? 0.2 : 0.15,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Open',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(int seconds, BuildContext context, bool isDark) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final divider = isDark ? DarkColors.divider : LightColors.divider;
    final textSecondary = isDark
        ? DarkColors.textSecondary
        : LightColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: divider),
      ),
      child: Column(
        children: [
          Text(
            'Time remaining for this pharmacy',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            '$minutes:${secs.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 44,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: seconds / 300,
              minHeight: 4,
              backgroundColor: divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                seconds > 60
                    ? AppColors.primaryGreen
                    : seconds > 30
                    ? AppColors.primaryBlue
                    : AppColors.accentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(
    RoutingStateModel state,
    BuildContext context,
    bool isDark,
  ) {
    final surfaceVariant = isDark
        ? DarkColors.surfaceVariant
        : LightColors.surfaceVariant;
    final divider = isDark ? DarkColors.divider : LightColors.divider;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${state.currentPharmacyIndex + 1}/${state.nearbyPharmacies.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Contacting', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Container(width: 1, height: 40, color: divider),
          Column(
            children: [
              Text(
                '${state.failedPharmacyIds.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('No Response', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingPharmacies(
    RoutingStateModel state,
    BuildContext context,
    bool isDark,
  ) {
    final remaining = state.nearbyPharmacies
        .skip(state.currentPharmacyIndex + 1)
        .toList();

    if (remaining.isEmpty) {
      return const SizedBox.shrink();
    }

    final surfaceVariant = isDark
        ? DarkColors.surfaceVariant
        : LightColors.surfaceVariant;
    final textSecondary = isDark
        ? DarkColors.textSecondary
        : LightColors.textSecondary;
    final textHint = isDark ? DarkColors.textHint : LightColors.textHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next in queue',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...remaining.asMap().entries.map((entry) {
          final index = entry.key;
          final pharmacy = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == remaining.length - 1 ? 0 : 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Text(
                    '${index + 2}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacy.name,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pharmacy.distance}km away',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: textHint),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOfferReceivedBanner(BuildContext context, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.celebration_rounded,
            color: AppColors.primaryGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offer Received! / تم استلام عرض سعر!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We found $count pharmacy offer(s) for your prescription.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPharmaciesFailedScreen(RoutingStateModel state, bool isDark, {bool isExplicitlyRejected = false}) {
    final textSecondary = isDark
        ? DarkColors.textSecondary
        : LightColors.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(isExplicitlyRejected ? 'Request Cancelled' : 'Search Completed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExplicitlyRejected ? Icons.cancel_outlined : Icons.sentiment_dissatisfied_rounded,
                size: 64,
                color: AppColors.accentRed,
              ),
              const SizedBox(height: 24),
              Text(
                isExplicitlyRejected ? 'Request Declined / Cancelled' : 'No Pharmacies Responded',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isExplicitlyRejected 
                    ? 'The request was declined by nearby pharmacies or cancelled. You can try resubmitting or contacting directly.'
                    : 'We contacted ${state.failedPharmacyIds.length} pharmacies but none responded. Please try again later or contact manually.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(routingStateNotifierProvider.notifier)
                        .resetRouting();
                    context.pop();
                  },
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacyRespondedScreen(RoutingStateModel state, bool isDark, List<dynamic> replies, int status) {
    final textSecondary = isDark
        ? DarkColors.textSecondary
        : LightColors.textSecondary;

    String displayName = 'Pharmacy';
    String pharmacyId = state.lockPharmacyId ?? '';

    // If lockPharmacyId is null, resolve it dynamically from the loaded replies!
    if (pharmacyId.isEmpty && replies.isNotEmpty) {
      final acceptedReply = replies.firstWhere((r) => r is Map, orElse: () => null);
      if (acceptedReply != null) {
        pharmacyId = _getVal(acceptedReply, 'pharmacyId')?.toString() ?? '';
      }
    }

    if (pharmacyId.isNotEmpty) {
      final matchingReply = replies.firstWhere(
        (r) => _getVal(r, 'pharmacyId')?.toString() == pharmacyId,
        orElse: () => null,
      );
      if (matchingReply != null) {
        displayName = _getVal(matchingReply, 'pharmacyName')?.toString() ?? 'Pharmacy';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy Responded')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 64,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 24),
              Text(
                '$displayName Responded!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your offer has been accepted. Open chat to coordinate with the pharmacy.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 32),

              // ── Open Chat CTA ──────────────────────────────────────────
              Builder(
                builder: (ctx) {
                  final authState = ref.read(authProvider);
                  final isPharmacy = ref.read(isPharmacyModeProvider);
                  final pharmacyMode = ref.read(pharmacyModeProvider);
                  final currentUserId = authState.user?.id ?? '';

                  final String otherUserId;
                  final String? pharmacyIdParam;

                  if (isPharmacy) {
                    otherUserId = state.patientId;
                    pharmacyIdParam = pharmacyMode.currentPharmacy?.id ?? pharmacyId;
                  } else {
                    otherUserId = pharmacyId;
                    pharmacyIdParam = null;
                  }

                  if (status == 2 && !isPharmacy) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (otherUserId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot open chat: Other user ID is empty. / لا يمكن فتح المحادثة: معرف الطرف الآخر فارغ.'),
                              ),
                            );
                            return;
                          }
                          context.push(
                            AppRoutes.prescriptionChat,
                            extra: {
                              'prescriptionId': state.id,
                              'otherUserId': otherUserId,
                              'currentUserId': currentUserId,
                              'isPharmacy': false,
                              'pharmacyId': null,
                              'otherUserName': displayName,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '💬 Chat with Pharmacy',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (otherUserId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot open chat: Other user ID is empty. / لا يمكن فتح المحادثة: معرف الطرف الآخر فارغ.'),
                            ),
                          );
                          return;
                        }
                        context.push(
                          AppRoutes.prescriptionChat,
                          extra: {
                            'prescriptionId': state.id,
                            'otherUserId': otherUserId,
                            'currentUserId': currentUserId,
                            'isPharmacy': isPharmacy,
                            'pharmacyId': pharmacyIdParam,
                            'otherUserName': displayName,
                          },
                        );
                      },
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text(
                        'Open Chat / فتح المحادثة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(routingStateNotifierProvider.notifier).resetRouting();
                    context.pop();
                  },
                  child: const Text('Back to Prescriptions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mock pharmacy model for display
