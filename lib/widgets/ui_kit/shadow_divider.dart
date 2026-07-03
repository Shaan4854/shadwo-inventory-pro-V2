import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Thin themed divider (0.5 px, border color). Optional `margin` param
/// so it can double as the top-border of a bottom-nav bar without a
/// second raw widget.
class ShadowDivider extends StatelessWidget {
  const ShadowDivider({
    super.key,
    this.margin = EdgeInsets.zero,
    this.color,
    this.thickness = 0.5,
  });

  final EdgeInsetsGeometry margin;
  final Color? color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: thickness,
      color: color ?? ShadowColors.border,
    );
  }
}
