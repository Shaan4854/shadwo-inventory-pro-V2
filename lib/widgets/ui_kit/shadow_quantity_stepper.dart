import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// +/- quantity counter, clamped to [min]/[max].
class ShadowQuantityStepper extends StatelessWidget {
  const ShadowQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;

  bool get _canDecrement => value > min;
  bool get _canIncrement => max == null || value < max!;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShadowColors.input,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShadowColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepperButton(
            icon: Icons.remove,
            enabled: _canDecrement,
            onTap: () => onChanged((value - 1).clamp(min, max ?? (value - 1))),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            alignment: Alignment.center,
            color: ShadowColors.background,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ShadowColors.foreground,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            enabled: _canIncrement,
            onTap: () => onChanged(max == null ? value + 1 : (value + 1).clamp(min, max!)),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: ShadowColors.muted,
          child: Icon(icon, size: 18, color: ShadowColors.foreground),
        ),
      ),
    );
  }
}
