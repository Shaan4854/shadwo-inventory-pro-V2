import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

enum ShadowButtonVariant { primary, secondary, ghost, danger, outline }

enum ShadowButtonSize { sm, md, lg }

/// Themed button. Five variants (primary/secondary/ghost/danger/outline)
/// per spec. Also handles a loading state and optional leading icon so
/// call sites never build their own button.
///
/// Interaction model:
///   - Scales to 0.97 on tap-down, restores on release (100 ms, easeInOut).
///   - Danger variant fires [HapticFeedback.mediumImpact]; all others
///     fire [HapticFeedback.lightImpact].
class ShadowButton extends StatefulWidget {
  const ShadowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ShadowButtonVariant.primary,
    this.size = ShadowButtonSize.md,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ShadowButtonVariant variant;
  final ShadowButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  State<ShadowButton> createState() => _ShadowButtonState();
}

class _ShadowButtonState extends State<ShadowButton> {
  bool _pressed = false;

  ({Color bg, Color fg, Color? border}) _colors() {
    switch (widget.variant) {
      case ShadowButtonVariant.primary:
        return (
          bg: ShadowColors.primary,
          fg: ShadowColors.primaryFg,
          border: null,
        );
      case ShadowButtonVariant.secondary:
        return (
          bg: ShadowColors.secondary,
          fg: ShadowColors.secondaryFg,
          border: ShadowColors.border,
        );
      case ShadowButtonVariant.ghost:
        return (
          bg: Colors.transparent,
          fg: ShadowColors.foreground,
          border: null,
        );
      case ShadowButtonVariant.danger:
        return (
          bg: ShadowColors.destructive,
          fg: Colors.white,
          border: null,
        );
      case ShadowButtonVariant.outline:
        return (
          bg: Colors.transparent,
          fg: ShadowColors.foreground,
          border: ShadowColors.border,
        );
    }
  }

  EdgeInsets _padding() {
    switch (widget.size) {
      case ShadowButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ShadowButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      case ShadowButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _fontSize() => switch (widget.size) {
        ShadowButtonSize.sm => 12,
        ShadowButtonSize.md => 14,
        ShadowButtonSize.lg => 16,
      };

  void _handleTap() {
    if (widget.variant == ShadowButtonVariant.danger) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final disabled = widget.onPressed == null || widget.loading;
    final fontSize = _fontSize();
    final labelStyle = ShadowTextStyles.body.copyWith(
      color: c.fg,
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
    );

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(c.fg),
            ),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: fontSize + 2, color: c.fg),
        if (widget.icon != null || widget.loading) const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return AnimatedScale(
      scale: (_pressed && !disabled) ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: Opacity(
        opacity: disabled ? 0.6 : 1.0,
        child: Material(
          color: c.bg,
          borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
          elevation:
              widget.variant == ShadowButtonVariant.primary && !disabled ? 2 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            onTap: disabled ? null : _handleTap,
            onHighlightChanged:
                disabled ? null : (v) => setState(() => _pressed = v),
            child: Container(
              padding: _padding(),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
                border: c.border == null
                    ? null
                    : Border.all(color: c.border!, width: 1),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
