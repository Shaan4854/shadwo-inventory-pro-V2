import 'package:flutter/material.dart';

/// The official Shadow Inventory Pro logo.
/// Uses the asset image if available, otherwise a placeholder.
class ShadowLogo extends StatelessWidget {
  const ShadowLogo({
    super.key,
    this.size = 40,
    this.useAsset = true,
  });

  final double size;
  final bool useAsset;

  @override
  Widget build(BuildContext context) {
    if (useAsset) {
      return Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        color: Theme.of(context).colorScheme.onPrimary,
        size: size * 0.6,
      ),
    );
  }
}
