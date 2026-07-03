import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum ShadowButtonVariant { primary, secondary, ghost, danger, outline }

enum ShadowButtonSize { sm, md, lg, xl }

/// 5-variant button per the design spec (primary/secondary/ghost/danger/
/// outline). Never use a raw [ElevatedButton]/[TextButton] directly.
class ShadowButton extends StatelessWidget {
  const ShadowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ShadowButtonVariant.primary,
    this.size = ShadowButtonSize.md,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ShadowButtonVariant variant;
  final ShadowButtonSize size;
  final IconData? icon;
  final bool isLoading;

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case ShadowButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ShadowButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case ShadowButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ShadowButtonSize.xl:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double get _fontSize => size == ShadowButtonSize.sm ? 12 : 14;

  Color get _bg {
    switch (variant) {
      case ShadowButtonVariant.primary:
        return ShadowColors.primary;
      case ShadowButtonVariant.secondary:
        return ShadowColors.secondary;
      case ShadowButtonVariant.ghost:
      case ShadowButtonVariant.outline:
        return Colors.transparent;
      case ShadowButtonVariant.danger:
        return ShadowColors.destructive;
    }
  }

  Color get _fg {
    switch (variant) {
      case ShadowButtonVariant.primary:
        return ShadowColors.primaryFg;
      case ShadowButtonVariant.secondary:
        return ShadowColors.secondaryFg;
      case ShadowButtonVariant.ghost:
      case ShadowButtonVariant.outline:
        return ShadowColors.foreground;
      case ShadowButtonVariant.danger:
        return Colors.white;
    }
  }

  BorderSide get _border {
    switch (variant) {
      case ShadowButtonVariant.outline:
        return BorderSide(color: ShadowColors.border.withValues(alpha: 0.8));
      case ShadowButtonVariant.secondary:
        return BorderSide(color: ShadowColors.border.withValues(alpha: 0.6));
      case ShadowButtonVariant.ghost:
        return BorderSide.none;
      case ShadowButtonVariant.primary:
      case ShadowButtonVariant.danger:
        return BorderSide.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: _bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _border,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onPressed,
          child: Padding(
            padding: _padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (isLoading) ...<Widget>[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_fg),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (icon != null) ...<Widget>[
                  Icon(icon, size: 16, color: _fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: _fg,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
