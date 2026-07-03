import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Pill-shaped filter chip with an active/inactive state (category
/// filters, sort options, etc).
class ShadowFilterChip extends StatelessWidget {
  const ShadowFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? ShadowColors.primary : ShadowColors.muted.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: active ? ShadowColors.primary : ShadowColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: active ? ShadowColors.primaryFg : ShadowColors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
