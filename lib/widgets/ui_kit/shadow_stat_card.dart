import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Stat card — colored 4px left border, tinted bg, uppercase label,
/// big value, small sub. Optional `onTap` gets a card-press animation.
class ShadowStatCard extends StatefulWidget {
  const ShadowStatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.accent,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? accent;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  State<ShadowStatCard> createState() => _ShadowStatCardState();
}

class _ShadowStatCardState extends State<ShadowStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: ShadowAnimations.fast,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? ShadowColors.accentDefault;
    // Accent-tinted glass surface: blend a whisper of the accent hue into
    // the top-lit card gradient.
    final tintTop = Color.alphaBlend(
      accent.withValues(alpha: 0.06),
      ShadowColors.palette.cardGradientTop,
    );
    final tintBottom = Color.alphaBlend(
      accent.withValues(alpha: 0.03),
      ShadowColors.palette.cardGradientBottom,
    );

    final card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tintTop, tintBottom],
        ),
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        border: Border.all(
          color: ShadowColors.glassHighlight,
          width: 0.8,
        ),
        boxShadow: [
          ...ShadowColors.cardShadow,
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ShadowTheme.cardPaddingH,
                    vertical: ShadowTheme.cardPaddingV,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.label.toUpperCase(),
                              style: ShadowTextStyles.statLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.icon != null)
                            Icon(
                              widget.icon,
                              size: 16,
                              color: accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.value,
                            style: ShadowTextStyles.statValue,
                          ),
                        ),
                      ),
                      if (widget.sub != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.sub!,
                          style: ShadowTextStyles.statSub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final s = 1 - (_c.value * (1 - ShadowAnimations.cardPressScale));
        return Transform.scale(scale: s, child: child);
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
          onTap: widget.onTap,
          onHighlightChanged: (v) => v ? _c.forward() : _c.reverse(),
          child: card,
        ),
      ),
    );
  }
}
