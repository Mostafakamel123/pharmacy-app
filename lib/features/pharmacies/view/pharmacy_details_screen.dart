// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/core/models/pharmacy_model.dart';
import 'package:pharmacy_app/core/services/geocoding_service.dart';

class PharmacyDetailsScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyDetailsScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> {
  String? _geocodedAddress;
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    if (widget.pharmacy.latitude == 0 && widget.pharmacy.longitude == 0) {
      if (mounted) {
        setState(() {
          _geocodedAddress = widget.pharmacy.address;
          _isLoadingAddress = false;
        });
      }
      return;
    }

    try {
      final resolved = await GeocodingService.getAddressFromCoordinates(
        widget.pharmacy.latitude,
        widget.pharmacy.longitude,
      );
      if (mounted) {
        setState(() {
          _geocodedAddress = resolved ?? widget.pharmacy.address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Error resolving pharmacy details address: $e');
      if (mounted) {
        setState(() {
          _geocodedAddress = widget.pharmacy.address;
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacy = widget.pharmacy;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: Stack(
        children: [
          // Content Area
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Clean Header (Cover Image + Refactored Profile Card)
              SliverToBoxAdapter(child: _HeroHeader(pharmacy: pharmacy)),
              
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              
              // Information Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Information',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? DarkColors.textPrimary
                              : LightColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Info Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _InfoCard(
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.accentRed,
                        iconBg: AppColors.accentRed.withOpacity(0.1),
                        label: 'Address',
                        value: _isLoadingAddress
                            ? 'Loading address...'
                            : (_geocodedAddress ?? pharmacy.address),
                        isLoading: _isLoadingAddress,
                      ),
                      const SizedBox(height: 8),
                      _InfoCard(
                        icon: Icons.schedule_rounded,
                        iconColor: AppColors.primaryGreen,
                        iconBg: AppColors.primaryGreen.withOpacity(0.1),
                        label: 'Working Hours',
                        value: pharmacy.workingHours,
                      ),
                      if (pharmacy.phone != null) ...[
                        const SizedBox(height: 8),
                        _InfoCard(
                          icon: Icons.phone_rounded,
                          iconColor: AppColors.primaryBlue,
                          iconBg: AppColors.primaryBlue.withOpacity(0.1),
                          label: 'Phone',
                          value: pharmacy.phone!,
                        ),
                      ],
                      if (pharmacy.hasDelivery &&
                          pharmacy.estimatedDeliveryMinutes != null) ...[
                        const SizedBox(height: 8),
                        _InfoCard(
                          icon: Icons.delivery_dining_rounded,
                          iconColor: AppColors.accentPurple,
                          iconBg: AppColors.accentPurple.withOpacity(0.1),
                          label: 'Estimated Delivery',
                          value: '~${pharmacy.estimatedDeliveryMinutes} min',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Services Section
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.primaryCyan,
                            ],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? DarkColors.textPrimary
                              : LightColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? DarkColors.card : LightColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: isDark
                            ? DarkColors.divider
                            : LightColors.divider,
                        width: 1,
                      ),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ServiceChip(
                          icon: Icons.local_pharmacy_rounded,
                          label: 'Medicines',
                          color: AppColors.primaryGreen,
                        ),
                        _ServiceChip(
                          icon: Icons.chat_rounded,
                          label: 'Consultation',
                          color: AppColors.accentPurple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom padding for actions
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          
          // Sticky Bottom Actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActions(pharmacy: pharmacy),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final PharmacyModel pharmacy;

  const _HeroHeader({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Clean Banner Cover Image
        Stack(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: (pharmacy.imageUrl != null && pharmacy.imageUrl!.isNotEmpty)
                    ? Image.network(
                        pharmacy.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultGradient(),
                      )
                    : _buildDefaultGradient(),
              ),
            ),
            // Back button positioned safely on top of the banner image
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // 2. Pharmacy Info Profile Card (No text overlaps!)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clear Circular Avatar Image
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: (pharmacy.imageUrl != null && pharmacy.imageUrl!.isNotEmpty)
                        ? Image.network(
                            pharmacy.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.local_pharmacy_rounded,
                              size: 32,
                              color: isDark ? Colors.white : AppColors.primaryBlue,
                            ),
                          )
                        : Icon(
                            Icons.local_pharmacy_rounded,
                            size: 32,
                            color: isDark ? Colors.white : AppColors.primaryBlue,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Pharmacy details column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (pharmacy.isVerified) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryBlue, Color(0xFF38BDF8)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Status, Rating and Distance Wrap (Responsive wrap)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusPill(isOpen: pharmacy.isOpen),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(
                                  pharmacy.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                                ),
                                Text(
                                  ' (${pharmacy.reviewCount})',
                                  style: TextStyle(fontSize: 10, color: isDark ? DarkColors.textHint : LightColors.textHint),
                                ),
                              ],
                            ),
                          ),
                          if (pharmacy.distance > 0.0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.near_me_rounded,
                                    size: 14,
                                    color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${pharmacy.distance.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pharmacy.isOpen
              ? [const Color(0xFF06B6D4), const Color(0xFF0EA5E9), const Color(0xFF10B981)]
              : [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isOpen;

  const _StatusPill({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.primaryGreen.withOpacity(0.12)
            : AppColors.accentRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.primaryGreen : AppColors.accentRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isOpen ? AppColors.primaryGreen : AppColors.accentRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final bool isLoading;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.card : LightColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark ? DarkColors.divider : LightColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? DarkColors.textHint : LightColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (isLoading)
                  const _ShimmerText(width: 180, height: 14)
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? DarkColors.textPrimary
                          : LightColors.textPrimary,
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

class _ShimmerText extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerText({required this.width, required this.height});

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.8).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final PharmacyModel pharmacy;

  const _BottomActions({required this.pharmacy});

  String _formatWhatsAppNumber(String phone) {
    final String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('01') && digits.length == 11) {
      return '2$digits';
    }
    return digits;
  }

  Future<void> _makeCall(String? phone, BuildContext context) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this pharmacy')),
      );
      return;
    }
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    try {
      final bool launched = await launchUrl(launchUri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $phone')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dialing: $e')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String? phone, BuildContext context) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No WhatsApp number available for this pharmacy')),
      );
      return;
    }
    final String formatted = _formatWhatsAppNumber(phone);
    final Uri whatsappUri = Uri.parse("https://wa.me/$formatted");
    try {
      final bool launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.background : LightColors.background,
        border: Border(
          top: BorderSide(
            color: isDark ? DarkColors.divider : LightColors.divider,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Call Button (Primary Styled CTA)
            Expanded(
              child: _ActionBtn(
                icon: Icons.phone_rounded,
                label: 'Call',
                color: AppColors.primaryBlue,
                isPrimary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _makeCall(pharmacy.phone, context);
                },
              ),
            ),
            const SizedBox(width: 12),
            // WhatsApp Button
            Expanded(
              child: _ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                isPrimary: false,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _openWhatsApp(pharmacy.phone, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse().then((_) => widget.onTap()),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? widget.color
                : widget.color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isPrimary ? Colors.white : widget.color,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.isPrimary ? Colors.white : widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}