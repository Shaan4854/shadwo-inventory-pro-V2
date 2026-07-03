import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';

/// Base card container — every other card/list-tile in the app should
/// wrap content in this instead of a raw [Card]/[Container].
class ShadowCard extends StatefulWidget {
  const ShadowCard({
    super.key,
    required this.child,
    this.interactive = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.margin,
  });

  final Widget child;

  /// Adds press feedback (scale + ripple) and requires [onTap].
  final bool interactive;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  State<ShadowCard> createState() => _ShadowCardState();
}

class _ShadowCardState extends State<ShadowCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.interactive) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final Widget card = AnimatedScale(
      scale: _pressed ? ShadowAnimation.cardPressScale : 1.0,
      duration: ShadowAnimation.cardPress,
      curve: ShadowAnimation.cardPressCurve,
      child: Container(
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: ShadowColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ShadowColors.border.withValues(alpha: 0.5)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: widget.child,
      ),
    );

    if (!widget.interactive) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        onHighlightChanged: _setPressed,
        child: card,
      ),
    );
  }
}
