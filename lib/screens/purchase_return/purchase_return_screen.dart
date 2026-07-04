import 'package:flutter/material.dart';
import '../_shared/return_screen.dart';

class PurchaseReturnScreen extends StatelessWidget {
  const PurchaseReturnScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ReturnScreen(kind: ReturnKind.purchase);
}
