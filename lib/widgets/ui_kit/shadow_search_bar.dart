import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Search bar with leading search icon + clear (X) button when non-empty.
class ShadowSearchBar extends StatelessWidget {
  const ShadowSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: ShadowColors.foreground, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: ShadowColors.mutedForeground),
            prefixIcon: const Icon(Icons.search, color: ShadowColors.mutedForeground, size: 18),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 16, color: ShadowColors.mutedForeground),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                      onClear?.call();
                    },
                  ),
            filled: true,
            fillColor: ShadowColors.input,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          ),
        );
      },
    );
  }
}
