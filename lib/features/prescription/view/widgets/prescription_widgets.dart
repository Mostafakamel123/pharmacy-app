// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

/// Medicine availability status indicator with emoji
class MedicineStatusIndicator extends StatelessWidget {
  final String status;
  final String? price;
  final int? quantity;

  const MedicineStatusIndicator({
    super.key,
    required this.status,
    this.price,
    this.quantity,
  }) : super();

  Color _getStatusColor() {
    if (status.contains('✅')) return Colors.green;
    if (status.contains('❌')) return AppColors.accentRed;
    if (status.contains('⚠️')) return AppColors.accentYellow;
    return LightColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (price != null)
            Text(
              'SAR $price',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          if (quantity != null)
            Text(
              'Qty: $quantity',
              style: const TextStyle(
                color: LightColors.textSecondary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

/// Pharmacy info card for chat context
class PharmacyContextCard extends StatelessWidget {
  final String pharmacyName;
  final String location;
  final double distance;
  final double rating;

  const PharmacyContextCard({
    super.key,
    required this.pharmacyName,
    required this.location,
    required this.distance,
    required this.rating,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withOpacity(0.2),
            ),
            child: const Center(
              child: Icon(
                Icons.store,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pharmacyName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: LightColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$distance km away',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: LightColors.textSecondary,
                                fontSize: 11,
                              ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.accentYellow,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Timer widget with circular progress
class TimerWidget extends StatelessWidget {
  final int seconds;
  final Duration totalDuration;
  final VoidCallback? onTimeUp;

  const TimerWidget({
    super.key,
    required this.seconds,
    this.totalDuration = const Duration(minutes: 5),
    this.onTimeUp,
  }) : super();

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final progress = seconds / totalDuration.inSeconds;

    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  seconds > 60
                      ? Colors.green
                      : seconds > 30
                          ? Colors.orange
                          : AppColors.accentRed,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$minutes:${secs.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                  ),
                  Text(
                    'remaining',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rotating pharmacy animation
class RotatingPharmacyAnimation extends StatefulWidget {
  final Duration duration;
  final Widget child;

  const RotatingPharmacyAnimation({
    super.key,
    this.duration = const Duration(seconds: 3),
    required this.child,
  }) : super();

  @override
  State<RotatingPharmacyAnimation> createState() =>
      _RotatingPharmacyAnimationState();
}

class _RotatingPharmacyAnimationState extends State<RotatingPharmacyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}

/// Pulse animation for pharmacy search
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  }) : super();

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Prescription request card summary
class PrescriptionRequestCard extends StatelessWidget {
  final String prescriptionId;
  final DateTime createdAt;
  final bool isImage;
  final String? imagePreview;

  const PrescriptionRequestCard({
    super.key,
    required this.prescriptionId,
    required this.createdAt,
    required this.isImage,
    this.imagePreview,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: LightColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isImage ? Icons.image : Icons.description,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isImage ? 'Prescription Image' : 'Text Prescription',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  createdAt.toString().split('.')[0],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LightColors.textSecondary,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
