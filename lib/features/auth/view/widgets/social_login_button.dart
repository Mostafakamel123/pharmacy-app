// import 'package:flutter/material.dart';
// import 'package:pharmacy_app/core/theme/app_colors.dart';

// /// Social login button
// class SocialLoginButton extends StatelessWidget {
//   final String text;
//   final IconData icon;
//   final VoidCallback? onPressed;
//   final Color? iconColor;
//   final Color? backgroundColor;

//   const SocialLoginButton({
//     super.key,
//     required this.text,
//     required this.icon,
//     this.onPressed,
//     this.iconColor,
//     this.backgroundColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Expanded(
//       child: SizedBox(
//         height: 50,
//         child: OutlinedButton(
//           onPressed: onPressed,
//           style: OutlinedButton.styleFrom(
//             backgroundColor: backgroundColor ??
//                 (isDark ? DarkColors.card : LightColors.card),
//             side: BorderSide(
//               color: isDark ? DarkColors.divider : LightColors.divider,
//               width: 1,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(AppRadius.md),
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 color: iconColor ?? AppColors.primaryBlue,
//                 size: 22,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 text,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }