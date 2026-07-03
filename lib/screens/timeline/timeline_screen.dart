import 'package:flutter/material.dart';

import '../_placeholder_screen.dart';

/// Timeline screen (opened from the "More" sheet) — built in Step 10.
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Timeline', stepLabel: 'Step 10');
  }
}
