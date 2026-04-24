import 'package:flutter/material.dart';

class QuickActionModel {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final VoidCallback onTap;

  const QuickActionModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.onTap,
  });
}
