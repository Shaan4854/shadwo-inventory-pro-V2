import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Pill-shaped filter chip — border-first design.
/// Selected = primary border + light tint background.
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
    final bg = selected
        ? ShadowColors.primary.withValues(alpha: 0.10)
        : Colors.transparent;
    final fg = selected ? ShadowColors.primary : ShadowColors.mutedForeground;
    final borderColor = selected ? ShadowColors.primary : ShadowColors.border;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.0 : 0.5,
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
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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
