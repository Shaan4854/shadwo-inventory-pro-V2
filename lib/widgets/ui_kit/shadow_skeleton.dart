import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Convenience skeletons for common list-item shapes.
class SkeletonList extends StatelessWidget {
  const SkeletonList.card({super.key, this.count = 5}) : _shape = _Shape.card;
  const SkeletonList.row({super.key, this.count = 5}) : _shape = _Shape.row;

  final int count;
  final _Shape _shape;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ShadowTheme.screenPaddingH,
          vertical: 8,
        ),
        child: Column(
          children: [
            for (int i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              switch (_shape) {
                _Shape.card => const _SkeletonCard(),
                _Shape.row => const _SkeletonRow(),
              },
            ],
          ],
        ),
      ),
    );
  }
}

enum _Shape { card, row }

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShadowColors.card,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        border: Border.all(color: ShadowColors.border, width: 0.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone(width: 120, height: 14),
          SizedBox(height: 10),
          Bone(width: double.infinity, height: 10),
          SizedBox(height: 6),
          Bone(width: 200, height: 10),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Bone(width: 40, height: 40, uniRadius: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone(width: 140, height: 12),
              SizedBox(height: 8),
              Bone(width: 80, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
