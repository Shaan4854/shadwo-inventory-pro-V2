import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

/// Uppercase section header (e.g. "RECENT PRODUCTS").
class ShadowSectionLabel extends StatelessWidget {
  const ShadowSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label.toUpperCase(), style: ShadowTextStyles.caption),
    );
  }
}
