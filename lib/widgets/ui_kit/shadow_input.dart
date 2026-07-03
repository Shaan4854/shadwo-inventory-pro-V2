import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Text field with optional label/error/prefix, matching the reference
/// Input component's focus-glow border treatment.
class ShadowInput extends StatelessWidget {
  const ShadowInput({
    super.key,
    this.controller,
    this.label,
    this.error,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? label;
  final String? error;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: ShadowTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          enabled: enabled,
          maxLines: maxLines,
          style: ShadowTextStyles.body,
          cursorColor: ShadowColors.primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: ShadowColors.mutedForeground),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: ShadowColors.mutedForeground),
            filled: true,
            fillColor: ShadowColors.input,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ShadowColors.border.withValues(alpha: 0.6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ShadowColors.border.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ShadowColors.primary.withValues(alpha: 0.4)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ShadowColors.destructive),
            ),
          ),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            error!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ShadowColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}
