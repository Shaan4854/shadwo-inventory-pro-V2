import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Shimmering placeholder box. Use `SkeletonList.card()` in list loading
/// states, or drop `ShadowSkeleton(width: h: )` inline.
class ShadowSkeleton extends StatefulWidget {
  const ShadowSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShadowSkeleton> createState() => _ShadowSkeletonState();
}

class _ShadowSkeletonState extends State<ShadowSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              ShadowColors.muted,
              ShadowColors.secondary,
              t,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Convenience skeletons for common list-item shapes.
class SkeletonList extends StatelessWidget {
  const SkeletonList.card({super.key, this.count = 5}) : _shape = _Shape.card;
  const SkeletonList.row({super.key, this.count = 5}) : _shape = _Shape.row;

  final int count;
  final _Shape _shape;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
        vertical: 8,
      ),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        switch (_shape) {
          case _Shape.card:
            return const _SkeletonCard();
          case _Shape.row:
            return const _SkeletonRow();
        }
      },
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
          ShadowSkeleton(width: 120, height: 14),
          SizedBox(height: 10),
          ShadowSkeleton(width: double.infinity, height: 10),
          SizedBox(height: 6),
          ShadowSkeleton(width: 200, height: 10),
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
        ShadowSkeleton(width: 40, height: 40, radius: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShadowSkeleton(width: 140, height: 12),
              SizedBox(height: 8),
              ShadowSkeleton(width: 80, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
