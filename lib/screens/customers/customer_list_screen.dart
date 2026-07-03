import 'package:flutter/material.dart';

import '../_placeholder_screen.dart';

/// Customers screen (opened from the "More" sheet) — built in Step 7.
class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Customers', stepLabel: 'Step 7');
  }
}
