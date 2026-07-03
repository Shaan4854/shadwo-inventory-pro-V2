import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/ui_kit/ui_kit.dart';

/// STUB — real implementation lands in the corresponding screen step.
class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShadowPageHeader(
          title: 'Suppliers',
          subtitle: 'Your supplier directory',
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

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: ShadowColors.foreground),
        ),
        body: body,
      ),
    );
  }
}
