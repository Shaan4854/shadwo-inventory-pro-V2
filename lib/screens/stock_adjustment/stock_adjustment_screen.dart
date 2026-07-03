import 'package:flutter/material.dart';

import '../_placeholder_screen.dart';

/// Stock Adjustment screen (opened from the "More" sheet) — built in
/// Step 12.
class StockAdjustmentScreen extends StatelessWidget {
  const StockAdjustmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Stock Adjustment', stepLabel: 'Step 12');
  }
}
