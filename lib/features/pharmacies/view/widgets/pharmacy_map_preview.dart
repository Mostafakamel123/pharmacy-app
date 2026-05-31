import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/core/models/pharmacy_model.dart';

class PharmacyMapPreview extends StatelessWidget {
  final List<PharmacyModel> pharmacies;
  final VoidCallback? onTap;

  const PharmacyMapPreview({
    super.key,
    required this.pharmacies,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E3A4A), const Color(0xFF2C5364)]
                  : [const Color(0xFFE0F2FE), const Color(0xFFDCFCE7)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark ? DarkColors.divider : LightColors.divider,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Map grid pattern (decorative)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: _GridPainter(),
                  ),
                ),
              ),
              // Pharmacy pins
              ...pharmacies.take(5).map((pharmacy) {
                final index = pharmacies.indexOf(pharmacy);
                final left = 30.0 + (index * 55.0) % 250;
                final top = 30.0 + (index * 25.0) % 80;
                return Positioned(
                  left: left,
                  top: top,
                  child: _MapPin(
                    pharmacy: pharmacy,
                  ),
                );
              }),
              // Open full map button
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF90CAF9)
                            : AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Full Map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF90CAF9)
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final PharmacyModel pharmacy;

  const _MapPin({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: pharmacy.isOpen
                ? AppColors.primaryGreen
                : const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            pharmacy.distance.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          Icons.location_on_rounded,
          size: 24,
          color: pharmacy.isOpen
              ? AppColors.primaryGreen
              : const Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (var i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    // Vertical lines
    for (var i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
