import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Stat card — colored 4px left border, flat surface, uppercase label,
/// big value, small sub. Optional `onTap` gets opacity press feedback.
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

class _ShadowStatCardState extends State<ShadowStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? ShadowColors.accentDefault;

    final card = Container(
      decoration: BoxDecoration(
        color: ShadowColors.card,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        border: Border.all(color: ShadowColors.border, width: 0.5),
      ),
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: accent),
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
                              size: 14,
                              color: accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
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
                        const SizedBox(height: 2),
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

    return AnimatedOpacity(
      opacity: _pressed ? ShadowAnimations.pressOpacity : 1.0,
      duration: ShadowAnimations.fast,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: card,
        ),
      ),
    );
  }
}
