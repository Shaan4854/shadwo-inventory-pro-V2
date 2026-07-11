import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../purchase/purchase_screen.dart';

/// Lists products at or below their reorder threshold so the user can
/// quickly raise a purchase order.
class ReorderScreen extends StatelessWidget {
  const ReorderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text('Needs Reorder', style: ShadowTextStyles.h4),
        ),
        body: Consumer<ProductProvider>(
          builder: (context, products, _) {
            final items = products.all
                .where((p) => p.isActive && p.isLowStock)
                .toList()
              ..sort((a, b) => a.stock.compareTo(b.stock));
            return items.isEmpty
                ? const ShadowEmptyState(
                    title: 'Nothing to reorder',
                    subtitle: 'All your products are above their reorder level.',
                    icon: Icons.check_circle_outline_rounded,
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      ShadowTheme.screenPaddingH,
                      12,
                      ShadowTheme.screenPaddingH,
                      24,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final row = RepaintBoundary(
                        child: ShadowCard(
                          onTap: () => Navigator.of(context).push(
                            ShadowAnimations.fadeInUpRoute(
                              page: const PurchaseScreen(),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              p.imagePath.isNotEmpty
                                  ? ClipRRect(
                                      clipBehavior: Clip.hardEdge,
                                      borderRadius:
                                          BorderRadius.circular(ShadowTheme.radiusMd),
                                      child: Image.file(
                                        File(p.imagePath),
                                        width: 40,
                                        height: 40,
                                        cacheWidth: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _fallback(p),
                                      ),
                                    )
                                  : _fallback(p),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      p.name,
                                      style: ShadowTextStyles.body
                                          .copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${p.stock} ${p.unit} on hand · reorder at ${p.alertThreshold}',
                                      style: ShadowTextStyles.bodyMuted
                                          .copyWith(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              ShadowButton(
                                label: 'Reorder',
                                variant: ShadowButtonVariant.secondary,
                                onPressed: () => Navigator.of(context).push(
                                  ShadowAnimations.fadeInUpRoute(
                                    page: const PurchaseScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (i > 8) return row;
                      return ShadowAnimations.staggerItem(index: i, child: row);
                    },
                  );
          },
        ),
      ),
    );
  }
}

Widget _fallback(Product p) => Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ShadowColors.muted,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
      ),
      child: Text(
        p.emoji.isEmpty ? '📦' : p.emoji,
        style: const TextStyle(fontSize: 18),
      ),
    );
