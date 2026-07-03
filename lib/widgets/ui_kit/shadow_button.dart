import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

enum ShadowButtonVariant { primary, secondary, ghost, danger, outline }

enum ShadowButtonSize { sm, md, lg }

/// Themed button. Five variants (primary/secondary/ghost/danger/outline)
/// per spec. Also handles a loading state and optional leading icon so
/// call sites never build their own button.
class ShadowButton extends StatelessWidget {
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

  ({Color bg, Color fg, Color? border}) _colors() {
    switch (variant) {
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
    switch (size) {
      case ShadowButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ShadowButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      case ShadowButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _fontSize() => switch (size) {
        ShadowButtonSize.sm => 12,
        ShadowButtonSize.md => 14,
        ShadowButtonSize.lg => 16,
      };

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final disabled = onPressed == null || loading;
    final labelStyle = ShadowTextStyles.body.copyWith(
      color: c.fg,
      fontWeight: FontWeight.w600,
      fontSize: _fontSize(),
    );
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(c.fg),
            ),
          )
        else if (icon != null)
          Icon(icon, size: _fontSize() + 2, color: c.fg),
        if ((icon != null || loading)) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: c.bg,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
        elevation: variant == ShadowButtonVariant.primary && !disabled ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
          onTap: disabled ? null : onPressed,
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
    );
  }
}
