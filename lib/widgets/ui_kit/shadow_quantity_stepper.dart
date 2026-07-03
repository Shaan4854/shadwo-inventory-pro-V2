import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Compact − / value / + control. Used in the POS cart and stock forms.
class ShadowQuantityStepper extends StatelessWidget {
  const ShadowQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.step = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final int step;

  void _bump(int delta) {
    var next = value + delta;
    if (next < min) next = min;
    if (max != null && next > max!) next = max!;
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShadowColors.muted,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
        border: Border.all(color: ShadowColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => _bump(-step),
              enabled: value > min),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: ShadowTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _btn(Icons.add, () => _bump(step),
              enabled: max == null || value < max!),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback tap, {required bool enabled}) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? tap : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: ShadowColors.foreground),
          ),
        ),
      ),
    );
  }
}
