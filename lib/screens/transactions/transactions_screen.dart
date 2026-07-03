import 'package:flutter/material.dart';

import '../_placeholder_screen.dart';

/// Transactions screen (opened from the "More" sheet) — built in Step 9.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Transactions', stepLabel: 'Step 9');
  }
}
