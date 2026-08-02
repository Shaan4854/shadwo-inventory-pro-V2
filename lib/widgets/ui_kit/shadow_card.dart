import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Themed card surface — flat with subtle border, no gradient, no glass.
/// `onTap` adds ripple + opacity press feedback.
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
    this.leftAccentWidth = 3,
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

class _ShadowCardState extends State<ShadowCard> {
  bool _pressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? ShadowColors.card;
    final border = widget.borderColor ?? ShadowColors.border;

    final content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        border: Border.all(color: border, width: 0.5),
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

    return AnimatedOpacity(
      opacity: _pressed ? ShadowAnimations.pressOpacity : 1.0,
      duration: ShadowAnimations.fast,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
          onTap: _handleTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: withAccent,
        ),
      ),
    );
  }
}
