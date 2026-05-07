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

  // Cache theme lookup to avoid repeated calls during build
  late bool _isDark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDark = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor = hasError
        ? AppColors.accentRed
        : _isDark
            ? DarkColors.divider
            : LightColors.divider;
    final iconColorValue = hasError
        ? AppColors.accentRed
        : _isDark
            ? const Color(0xFF90CAF9)
            : AppColors.primaryBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        // Use Container with child TextField instead of decoration prefixIcon
        // for better performance (avoids rebuilding icon on every change)
        Container(
          decoration: BoxDecoration(
            color: _isDark ? DarkColors.card : LightColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            // Performance: enable suggestions only if needed
            enableSuggestions: !widget.isPassword,
            autocorrect: !widget.isPassword,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: _isDark ? DarkColors.textHint : LightColors.textHint,
                fontSize: 14,
              ),
              prefixIcon: widget.icon != null
                  ? Icon(
                      widget.icon,
                      color: iconColorValue,
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _isDark
                            ? DarkColors.textHint
                            : LightColors.textHint,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      // Reduce tap target for faster response
                      padding: const EdgeInsets.all(8),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              // Prevent counter from being built
              counterText: '',
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