import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Thin horizontal rule, per spec's "simple line" divider.
///
/// Defaults to the content-separator spacing (24px above/below). Pass
/// margin to override, e.g. EdgeInsets.zero for a hairline border
/// use (nav bar top border, sheet chrome) where no extra gap is wanted.
class ShadowDivider extends StatelessWidget {
  const ShadowDivider({super.key, this.margin = const EdgeInsets.symmetric(vertical: 24)});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: margin,
      color: ShadowColors.border.withValues(alpha: 0.4),
    );
  }
}
