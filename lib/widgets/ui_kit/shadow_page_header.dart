import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'theme_toggle_button.dart';

/// Page header used at the top of every top-level screen. Title (h1) +
/// optional subtitle + optional trailing widget (usually an action
/// button). Also hosts the quick light/dark theme toggle at the far right
/// (set [showThemeToggle] to false to hide it, e.g. on a Settings screen
/// that already exposes the control).
class ShadowPageHeader extends StatelessWidget {
  const ShadowPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.showThemeToggle = true,
    this.padding = const EdgeInsets.fromLTRB(
      ShadowTheme.screenPaddingH,
      12,
      ShadowTheme.screenPaddingH,
      12,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final bool showThemeToggle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ShadowTextStyles.h1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: ShadowTextStyles.bodyMuted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
          if (showThemeToggle) ...[
            const SizedBox(width: 8),
            const ThemeToggleButton(),
          ],
        ],
      ),
    );
  }
}
