import 'package:flutter/material.dart';
import '../_shared/return_screen.dart';

class SalesReturnScreen extends StatelessWidget {
  const SalesReturnScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ReturnScreen(kind: ReturnKind.sales);
}
