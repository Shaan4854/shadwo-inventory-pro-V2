import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 7 badge variants per spec: default, sage, terracotta, warning, muted,
/// success, error.
enum ShadowBadgeVariant { defaultVariant, sage, terracotta, warning, muted, success, error }

class _BadgeColors {
  const _BadgeColors(this.bg, this.fg, this.border);
  final Color bg;
  final Color fg;
  final Color border;
}

_BadgeColors _colorsFor(ShadowBadgeVariant variant) {
  switch (variant) {
    case ShadowBadgeVariant.defaultVariant:
      return _BadgeColors(
        ShadowColors.primary.withValues(alpha: 0.15),
        ShadowColors.primary,
        ShadowColors.primary.withValues(alpha: 0.3),
      );
    case ShadowBadgeVariant.sage:
      return const _BadgeColors(
        Color(0x2622C55E),
        Color(0xFF22C55E),
        Color(0x4D22C55E),
      );
    case ShadowBadgeVariant.terracotta:
      return const _BadgeColors(
        Color(0x26F97316),
        Color(0xFFF97316),
        Color(0x4DF97316),
      );
    case ShadowBadgeVariant.warning:
      return const _BadgeColors(
        Color(0x26F59E0B),
        Color(0xFFF59E0B),
        Color(0x4DF59E0B),
      );
    case ShadowBadgeVariant.muted:
      return _BadgeColors(
        ShadowColors.muted.withValues(alpha: 0.6),
        ShadowColors.mutedForeground,
        ShadowColors.border.withValues(alpha: 0.4),
      );
    case ShadowBadgeVariant.success:
      return const _BadgeColors(
        Color(0x2610B981),
        Color(0xFF10B981),
        Color(0x4D10B981),
      );
    case ShadowBadgeVariant.error:
      return _BadgeColors(
        ShadowColors.destructive.withValues(alpha: 0.15),
        ShadowColors.destructive,
        ShadowColors.destructive.withValues(alpha: 0.3),
      );
  }
}

class ShadowBadge extends StatelessWidget {
  const ShadowBadge({
    super.key,
    required this.label,
    this.variant = ShadowBadgeVariant.defaultVariant,
  });

  final String label;
  final ShadowBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final _BadgeColors colors = _colorsFor(variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.fg,
        ),
      ),
    );
  }
}
