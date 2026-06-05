// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/core/config/env_config.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/features/pharmacy_mode/widgets/pharmacy_drawer.dart';
import 'package:Elaaj/features/pharmacies/view/edit_pharmacy/edit_pharmacy_screen.dart';
import 'package:Elaaj/features/pharmacies/controller/my_pharmacies_provider.dart';

/// State-of-the-art Pharmacy Profile Screen
/// Displays only the actual API data in a premium, elegant, and interactive way.
class PharmacyProfileScreen extends ConsumerStatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  ConsumerState<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends ConsumerState<PharmacyProfileScreen> {
  
  // Method to copy text to clipboard with a premium snackbar
  void _copyToClipboard(BuildContext context, String text, String label) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تم نسخ $label بنجاح!',
                style: const TextStyle(
                  fontFamily: 'Cairo', 
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Pharmacy logo image widget with fallback UI
  Widget _buildPharmacyLogo(String? logoUrl, String name) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      final fullUrl = logoUrl.startsWith('http') ? logoUrl : '${EnvConfig.apiBaseUrl}$logoUrl';
      return Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md - 2),
          child: Image.network(
            fullUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildLogoFallback(name),
          ),
        ),
      );
    }
    return _buildLogoFallback(name);
  }

  Widget _buildLogoFallback(String name) {
    final firstChar = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text(
          firstChar,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  // Active status badge
  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.12) : Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isActive ? Colors.green.withOpacity(0.5) : Colors.amber.withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'نشط الآن' : 'مغلق مؤقتاً',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.amber,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  // Home delivery support badge
  Widget _buildDeliveryBadge(bool hasDelivery) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hasDelivery ? AppColors.primaryGreen.withOpacity(0.12) : AppColors.accentRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: hasDelivery ? AppColors.primaryGreen.withOpacity(0.3) : AppColors.accentRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasDelivery ? Icons.local_shipping_rounded : Icons.store_mall_directory_rounded,
            color: hasDelivery ? AppColors.primaryGreen : AppColors.accentRed,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            hasDelivery ? 'توصيل متاح' : 'استلام فقط',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: hasDelivery ? AppColors.primaryGreen : AppColors.accentRed,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  // Elegant helper to build information display cards
  Widget _buildProfileInfoCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? copyText,
    String? copyLabel,
    Widget? actionWidget,
  }) {
    final cardBg = isDark ? DarkColors.surface : Colors.white;
    final textCol = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final subtitleCol = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final borderCol = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.12) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: copyText != null && copyLabel != null
            ? () => _copyToClipboard(context, copyText, copyLabel)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          key: ValueKey('card_$title'),
          child: Row(
            textDirection: TextDirection.rtl, // Content direction for Arabic readability
            children: [
              // Info Icon Indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Text Content (Title & Value)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtitleCol,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                  ],
                ),
              ),
              // Custom Action (e.g. Copy indicator icon)
              if (actionWidget != null) ...[
                const SizedBox(width: AppSpacing.md),
                actionWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Build the fixed header component
  Widget _buildFixedHeader(BuildContext context, dynamic currentPharmacy, bool isDark) {
    return SizedBox(
      height: 256,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gorgeous gradient background as cover
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.xxl),
                bottomRight: Radius.circular(AppRadius.xxl),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Open Drawer Button
                      Builder(
                        builder: (innerContext) => GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Scaffold.of(innerContext).openDrawer();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // Page Title
                      const Text(
                        'ملف الصيدلية',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      // Spacer to balance menu button
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Glassmorphic Card overlap
          Positioned(
            top: 130,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark 
                    ? DarkColors.surface.withOpacity(0.9) 
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.12) 
                      : Colors.black.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Elegant Circular Logo
                  _buildPharmacyLogo(currentPharmacy.logoUrl, currentPharmacy.name),
                  const SizedBox(width: AppSpacing.lg),
                  // Pharmacy Details (Name, Status)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentPharmacy.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Active and Delivery Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildStatusBadge(currentPharmacy.isActive),
                            _buildDeliveryBadge(currentPharmacy.hasDelivery),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPharmacy = ref.watch(currentPharmacyProvider);
    final isOwner = ref.watch(isCurrentPharmacyOwnerProvider);

    // If no pharmacy selected, show empty state
    if (currentPharmacy == null) {
      return const _EmptyProfileState();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? DarkColors.background : LightColors.background;

    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: PharmacyDrawer(currentPharmacy),
      body: Column(
        children: [
          _buildFixedHeader(context, currentPharmacy, isDark),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryBlue,
              backgroundColor: isDark ? DarkColors.surface : Colors.white,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await ref.read(myPharmaciesProvider.notifier).loadUserPharmacies();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                children: [
                  // Section Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md, right: AppSpacing.xs),
                    child: Text(
                      'بيانات الصيدلية المسجلة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),

                  // Working Hours Card
                  _buildProfileInfoCard(
                    context: context,
                    isDark: isDark,
                    title: 'ساعات العمل اليومية',
                    value: currentPharmacy.workingHours ?? 'غير محدد',
                    icon: Icons.access_time_filled_rounded,
                    iconColor: AppColors.accentYellow,
                    copyText: currentPharmacy.workingHours,
                    copyLabel: 'ساعات العمل',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Phone Contact Card
                  _buildProfileInfoCard(
                    context: context,
                    isDark: isDark,
                    title: 'رقم الهاتف والتواصل',
                    value: currentPharmacy.phone ?? 'غير متوفر',
                    icon: Icons.phone_rounded,
                    iconColor: AppColors.primaryBlue,
                    copyText: currentPharmacy.phone,
                    copyLabel: 'رقم الهاتف',
                    actionWidget: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Complete Address Card
                  _buildProfileInfoCard(
                    context: context,
                    isDark: isDark,
                    title: 'العنوان الجغرافي المسجل',
                    value: currentPharmacy.address,
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.accentRed,
                    copyText: currentPharmacy.address,
                    copyLabel: 'العنوان',
                    actionWidget: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.accentRed,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // GPS Coordinates Card
                  _buildProfileInfoCard(
                    context: context,
                    isDark: isDark,
                    title: 'إحداثيات الموقع (GPS)',
                    value: 'Lat: ${currentPharmacy.latitude.toStringAsFixed(6)}\nLng: ${currentPharmacy.longitude.toStringAsFixed(6)}',
                    icon: Icons.map_rounded,
                    iconColor: AppColors.primaryGreen,
                    copyText: '${currentPharmacy.latitude}, ${currentPharmacy.longitude}',
                    copyLabel: 'الإحداثيات الجغرافية',
                    actionWidget: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Edit button — only for Owners
                  if (isOwner)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPharmacyScreen(pharmacy: currentPharmacy),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'تعديل بيانات الصيدلية',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Read-only notice for Admins
                  if (!isOwner)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: Colors.orange.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'أنت مسؤول (Admin) — لا يمكنك تعديل بيانات الصيدلية',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Safe bottom spacer for navigation comfort
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== Empty Profile State Widget ========================

class _EmptyProfileState extends StatelessWidget {
  const _EmptyProfileState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final subtitleCol = isDark ? DarkColors.textSecondary : LightColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 68,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'لم يتم تحديد صيدلية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'يرجى استخدام القائمة الجانبية أو التبديل لوضع الصيدلية لعرض البروفايل الخاص بك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleCol,
                  fontFamily: 'Cairo',
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
