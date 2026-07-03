import 'package:flutter/material.dart';

import '../../widgets/ui_kit/ui_kit.dart';

/// STUB — real implementation lands in the corresponding screen step.
class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShadowPageHeader(
          title: 'Purchase',
          subtitle: 'Record supplier purchases',
        ),
        const Expanded(
          child: ShadowEmptyState(
            title: 'Coming soon',
            subtitle: 'This screen is a placeholder — content is built in a later step.',
            icon: Icons.construction_rounded,
          ),
        ),
      ],
    );

    return body;
  }
}
