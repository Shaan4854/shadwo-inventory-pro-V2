import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Themed text input. Wraps `TextField` with the input decoration theme
/// already defined in `ShadowTheme`; adds label + helper/error rows.
class ShadowInput extends StatelessWidget {
  const ShadowInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: ShadowTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          autofocus: autofocus,
          textInputAction: textInputAction,
          style: ShadowTextStyles.body,
          cursorColor: ShadowColors.primary,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                prefixIcon == null ? null : Icon(prefixIcon, size: 18),
            suffixIcon: suffixIcon,
            errorText: errorText,
          ),
        ),
        if (helper != null && errorText == null) ...[
          const SizedBox(height: 4),
          Text(helper!, style: ShadowTextStyles.bodyMuted),
        ],
      ],
    );
  }
}
