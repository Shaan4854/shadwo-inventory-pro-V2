import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Centered empty state — used whenever a list/query has no results.
class ShadowEmptyState extends StatelessWidget {
  const ShadowEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.description,
    this.action,
  });

  final IconData? icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 56, color: ShadowColors.mutedForeground.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: ShadowTextStyles.h3,
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: ShadowColors.mutedForeground),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
