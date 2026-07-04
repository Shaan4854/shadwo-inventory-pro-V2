import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Pill-shaped filter chip — used for category filters, stock-state
/// filters, etc. Not a Material `FilterChip`, styled from scratch to
/// match the design reference.
///
/// Fires [HapticFeedback.selectionClick] on every tap so filter
/// changes feel immediate even before the list re-renders.
class ShadowFilterChip extends StatelessWidget {
  const ShadowFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  void _handleTap() {
    HapticFeedback.selectionClick();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bg = selected ? ShadowColors.primary : ShadowColors.muted;
    final fg = selected ? ShadowColors.primaryFg : ShadowColors.foreground;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
            border: Border.all(
              color: selected ? ShadowColors.primary : ShadowColors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: ShadowTextStyles.body.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
