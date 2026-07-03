import 'package:flutter/material.dart';

import '../_placeholder_screen.dart';

/// Suppliers screen (opened from the "More" sheet) — built in Step 8.
class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Suppliers', stepLabel: 'Step 8');
  }
}
