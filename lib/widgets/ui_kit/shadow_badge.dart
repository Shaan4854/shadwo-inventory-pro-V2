import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Badge variants — spec calls for 7 semantic colors.
enum ShadowBadgeVariant {
  neutral,
  primary,
  success,
  warning,
  danger,
  info,
  muted,
}

/// Pill / chip label used for status ("Low Stock"), category tags,
/// icon-overlay notification dots (`compact: true`), etc.
///
/// Contract:
///   - Text is ALWAYS `maxLines: 1` + `overflow: ellipsis`, no matter the
///     variant — call sites must never re-implement overflow.
///   - `compact: true` shrinks padding + font and forces a min square of
///     ~16 so single-digit numbers stay circular; use for nav-icon
///     overlays. Never reuse the default pill sizing over a small icon.
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
        return (bg: ShadowColors.primary, fg: ShadowColors.primaryFg);
      case ShadowBadgeVariant.success:
        return (bg: ShadowColors.accentSage, fg: ShadowColors.primaryFg);
      case ShadowBadgeVariant.warning:
        return (bg: ShadowColors.accentWarning, fg: ShadowColors.primaryFg);
      case ShadowBadgeVariant.danger:
        return (bg: ShadowColors.destructive, fg: Colors.white);
      case ShadowBadgeVariant.info:
        return (bg: ShadowColors.accent, fg: ShadowColors.primaryFg);
      case ShadowBadgeVariant.muted:
        return (bg: ShadowColors.muted, fg: ShadowColors.mutedForeground);
      case ShadowBadgeVariant.neutral:
        return (bg: ShadowColors.secondary, fg: ShadowColors.foreground);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
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
          borderRadius: BorderRadius.circular(100),
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
