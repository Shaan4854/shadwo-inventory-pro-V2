import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Badge variants — 7 semantic colors.
enum ShadowBadgeVariant {
  neutral,
  primary,
  success,
  warning,
  danger,
  info,
  muted,
}

/// Pill / chip label used for status, category tags, notification dots.
///
/// Design: subtle background tint (not solid fill), refined typography.
class ShadowBadge extends StatelessWidget {
  const ShadowBadge({
    super.key,
    required this.label,
    this.variant = ShadowBadgeVariant.neutral,
    this.compact = false,
    this.icon,
  });

  final String label;
  final ShadowBadgeVariant variant;
  final bool compact;
  final IconData? icon;

  ({Color bg, Color fg}) _colors() {
    switch (variant) {
      case ShadowBadgeVariant.primary:
        return (bg: ShadowColors.primary.withValues(alpha: 0.12), fg: ShadowColors.primary);
      case ShadowBadgeVariant.success:
        return (bg: ShadowColors.accentSage.withValues(alpha: 0.12), fg: ShadowColors.accentSage);
      case ShadowBadgeVariant.warning:
        return (bg: ShadowColors.accentWarning.withValues(alpha: 0.12), fg: ShadowColors.accentWarning);
      case ShadowBadgeVariant.danger:
        return (bg: ShadowColors.destructive.withValues(alpha: 0.12), fg: ShadowColors.destructive);
      case ShadowBadgeVariant.info:
        return (bg: ShadowColors.accent.withValues(alpha: 0.12), fg: ShadowColors.accent);
      case ShadowBadgeVariant.muted:
        return (bg: ShadowColors.muted, fg: ShadowColors.mutedForeground);
      case ShadowBadgeVariant.neutral:
        return (bg: ShadowColors.muted, fg: ShadowColors.foreground);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
    final textStyle = (compact
            ? ShadowTextStyles.badgeCompact
            : ShadowTextStyles.badge)
        .copyWith(color: c.fg);
    final constraints = compact
        ? const BoxConstraints(minWidth: 16, minHeight: 16)
        : const BoxConstraints();
    return ConstrainedBox(
      constraints: constraints,
      child: Container(
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 10 : 12, color: c.fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
