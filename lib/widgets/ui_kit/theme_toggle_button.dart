import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';

/// Compact glass icon button that flips between light and dark mode.
///
/// Shows a sun in dark mode (tap → light) and a moon in light mode
/// (tap → dark), with a soft crossfade/scale between the two. Fires a
/// selection-click haptic. Dropped into the page header trailing slot so
/// every top-level screen gets an instant theme toggle.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeController>().isDark;
    return Semantics(
      button: true,
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<ThemeController>().toggle();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ShadowColors.cardSurface,
              border: Border.all(color: ShadowColors.glassHighlight, width: 0.8),
              boxShadow: ShadowColors.cardShadow,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween<double>(begin: 0.6, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey<bool>(isDark),
                size: 20,
                color: isDark ? ShadowColors.accentWarning : ShadowColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
