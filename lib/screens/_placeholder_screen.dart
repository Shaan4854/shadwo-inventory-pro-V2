import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui_kit/shadow_empty_state.dart';

/// Temporary stand-in body for a screen not yet built (per the master
/// prompt's screen build order). Each real screen file below wraps this
/// so [ShadowAppShell] has something to route to today; every usage is
/// replaced in that screen's own approved step — this file itself is
/// deleted once the last placeholder screen is implemented.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.stepLabel});

  final String title;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShadowColors.background,
      child: SafeArea(
        child: Center(
          child: ShadowEmptyState(
            icon: Icons.construction_outlined,
            title: title,
            description: 'Not built yet — $stepLabel.',
          ),
        ),
      ),
    );
  }
}
