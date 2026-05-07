import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

/// Auth text field widget with consistent styling
class AuthTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.keyboardType,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onTap,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? DarkColors.card : LightColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasError
                  ? AppColors.accentRed
                  : isDark
                      ? DarkColors.divider
                      : LightColors.divider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: isDark ? DarkColors.textHint : LightColors.textHint,
                fontSize: 14,
              ),
              prefixIcon: widget.icon != null
                  ? Icon(
                      widget.icon,
                      color: hasError
                          ? AppColors.accentRed
                          : isDark
                              ? const Color(0xFF90CAF9)
                              : AppColors.primaryBlue,
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isDark
                            ? DarkColors.textHint
                            : LightColors.textHint,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}