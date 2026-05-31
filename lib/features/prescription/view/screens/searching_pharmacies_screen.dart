// ignore_for_file: use_super_parameters, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/prescription/model/routing_state_model.dart';
import 'package:pharmacy_app/core/models/pharmacy_model.dart';
import 'package:pharmacy_app/features/prescription/controller/prescription_providers.dart';

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
  Timer? _routingTimer;

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

    // Start countdown timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(countdownTimerNotifierProvider.notifier).start();
      _startRoutingLogic();
    });
  }

  void _startRoutingLogic() {
    _routingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = ref.read(countdownTimerNotifierProvider);

      if (remaining <= 0 && mounted) {
        // Time's up, move to next pharmacy
        ref.read(routingStateNotifierProvider.notifier).moveToNextPharmacy();
        ref.read(countdownTimerNotifierProvider.notifier).reset();
        ref.read(countdownTimerNotifierProvider.notifier).start();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _routingTimer?.cancel();
    super.dispose();
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

    // Check if all pharmacies failed
    if (routingState.status == RoutingStatus.allPharmaciesFailed) {
      return _buildAllPharmaciesFailedScreen(routingState, isDark);
    }

    // Check if pharmacy responded
    if (routingState.status == RoutingStatus.pharmacyResponded) {
      return _buildPharmacyRespondedScreen(routingState, isDark);
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
              const SizedBox(height: 24),

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
    final bgColor = isDark ? DarkColors.surface : LightColors.surface;
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
        }).toList(),
      ],
    );
  }

  Widget _buildAllPharmaciesFailedScreen(RoutingStateModel state, bool isDark) {
    final textSecondary = isDark
        ? DarkColors.textSecondary
        : LightColors.textSecondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Search Completed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 64,
                color: AppColors.accentRed,
              ),
              const SizedBox(height: 24),
              Text(
                'No Pharmacies Responded',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We contacted ${state.failedPharmacyIds.length} pharmacies but none responded. Please try again later or contact manually.',
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

  Widget _buildPharmacyRespondedScreen(RoutingStateModel state, bool isDark) {
    final textSecondary = isDark
        ? DarkColors.textSecondary
        : LightColors.textSecondary;

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
                '${state.lockPharmacyId} Responded!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connecting you with the pharmacy...',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mock pharmacy model for display
