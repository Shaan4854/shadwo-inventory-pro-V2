import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'theme_toggle_button.dart';

/// Page header — title + optional subtitle + trailing.
/// Tighter, more typographic than the previous version.
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
      10,
      ShadowTheme.screenPaddingH,
      8,
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
            const SizedBox(width: 10),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
          if (showThemeToggle) ...[
            const SizedBox(width: 6),
            const ThemeToggleButton(),
          ],
        ],
      ),
    );
  }
}
