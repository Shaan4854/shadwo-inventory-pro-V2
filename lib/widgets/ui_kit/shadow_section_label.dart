import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

/// Uppercase section label — "RECENT PRODUCTS", "QUICK METRICS", etc.
class ShadowSectionLabel extends StatelessWidget {
  const ShadowSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: ShadowTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
