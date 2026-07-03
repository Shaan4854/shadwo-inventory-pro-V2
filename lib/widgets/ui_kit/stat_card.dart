import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';

/// Accent color choices for [ShadowStatCard]'s left border + tint.
enum ShadowStatAccent { defaultAccent, sage, olive, terracotta, warning }

Color _accentColor(ShadowStatAccent accent) {
  switch (accent) {
    case ShadowStatAccent.defaultAccent:
      return ShadowColors.accentDefault;
    case ShadowStatAccent.sage:
      return ShadowColors.accentSage;
    case ShadowStatAccent.olive:
      return ShadowColors.accentOlive;
    case ShadowStatAccent.terracotta:
      return ShadowColors.accentTerracotta;
    case ShadowStatAccent.warning:
      return ShadowColors.accentWarning;
  }
}

/// Dashboard stat card — colored left border, big value, small label/sub.
class ShadowStatCard extends StatelessWidget {
  const ShadowStatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.accent = ShadowStatAccent.defaultAccent,
  });

  final String label;
  final String value;
  final String? sub;
  final ShadowStatAccent accent;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _accentColor(accent);

    return ShadowAnimation.wrapScaleIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accentColor.withValues(alpha: 0.05),
            ShadowColors.card,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
            top: BorderSide(color: ShadowColors.border.withValues(alpha: 0.5)),
            right: BorderSide(color: ShadowColors.border.withValues(alpha: 0.5)),
            bottom: BorderSide(color: ShadowColors.border.withValues(alpha: 0.5)),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: ShadowColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: ShadowColors.foreground,
              ),
            ),
            if (sub != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                sub!,
                style: const TextStyle(
                  fontSize: 12,
                  color: ShadowColors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
