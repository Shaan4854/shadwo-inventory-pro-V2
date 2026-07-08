import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Themed card surface — bg=card, border=border@0.5, radius 16, padding
/// 20h/18v, elevation 2. `onTap` upgrades it to an interactive variant
/// with ripple + card-press scale animation.
///
/// When `onTap` is provided the card also fires
/// [HapticFeedback.lightImpact] on each tap so every tappable list
/// row/card feels responsive without call sites needing to wire haptics
/// individually.
///
/// Do NOT use this for chrome (nav-bar backgrounds, flat rows inside an
/// already-card bottom sheet) — use a raw Container/DecoratedBox there.
class ShadowCard extends StatefulWidget {
  const ShadowCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: ShadowTheme.cardPaddingH,
      vertical: ShadowTheme.cardPaddingV,
    ),
    this.borderColor,
    this.backgroundColor,
    this.leftAccent,
    this.leftAccentWidth = 4,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? leftAccent;
  final double leftAccentWidth;

  @override
  State<ShadowCard> createState() => _ShadowCardState();
}

class _ShadowCardState extends State<ShadowCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: ShadowAnimations.fast,
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Glass surface: a subtly top-lit gradient fill (no blur), a hairline
    // highlight border to catch the light, and a palette-aware soft shadow.
    final bg = widget.backgroundColor;
    final content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        gradient: bg == null ? ShadowColors.cardSurface : null,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        border: Border.all(
          color: widget.borderColor?.withValues(alpha: 0.5) ??
              ShadowColors.glassHighlight,
          width: 0.8,
        ),
        boxShadow: ShadowColors.cardShadow,
      ),
      child: widget.child,
    );

    final withAccent = widget.leftAccent == null
        ? content
        : ClipRRect(
            clipBehavior: Clip.hardEdge,
            borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
            child: Stack(
              children: [
                content,
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: widget.leftAccentWidth,
                    color: widget.leftAccent,
                  ),
                ),
              ],
            ),
          );

    if (widget.onTap == null) return withAccent;

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
          onTap: _handleTap,
          onHighlightChanged: (v) => v ? _c.forward() : _c.reverse(),
          child: withAccent,
        ),
      ),
    );
  }
}
