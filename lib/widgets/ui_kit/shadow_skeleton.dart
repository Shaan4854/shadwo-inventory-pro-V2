import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Pulsing placeholder block(s) — use while a [FutureBuilder]/[Consumer]
/// is loading, instead of a bare [CircularProgressIndicator].
class ShadowSkeleton extends StatefulWidget {
  const ShadowSkeleton({super.key, this.count = 1, this.height = 48});

  final int count;
  final double height;

  @override
  State<ShadowSkeleton> createState() => _ShadowSkeletonState();
}

class _ShadowSkeletonState extends State<ShadowSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        final double opacity = 0.4 + (_controller.value * 0.3);
        return Column(
          children: List<Widget>.generate(widget.count, (int i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == widget.count - 1 ? 0 : 12),
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: ShadowColors.muted.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
