import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import 'product_form_sheet.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  Future<void> _confirmDelete(BuildContext context, Product p) async {
    final ok = await ShadowConfirmDialog.show(
      context,
      title: 'Delete product?',
      message: '"${p.name}" will be removed from the catalog. '
          'Existing transactions keep their records.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;
    if (!context.mounted) return;
    await context.read<ProductProvider>().deleteProduct(p.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _openEdit(BuildContext context, Product p) {
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(
        page: ProductFormSheet(editing: p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final p = provider.byId(productId);
        return DecoratedBox(
          decoration:
              const BoxDecoration(gradient: ShadowColors.pageBackground),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme:
                  const IconThemeData(color: ShadowColors.foreground),
              actions: [
                if (p != null) ...[
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _openEdit(context, p),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _confirmDelete(context, p),
                  ),
                ],
              ],
            ),
            body: p == null
                ? const ShadowEmptyState(
                    title: 'Product not found',
                    subtitle: 'It may have been deleted from another screen.',
                    icon: Icons.help_outline_rounded,
                  )
                : _DetailBody(product: p),
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final variant = product.isOutOfStock
        ? ShadowBadgeVariant.danger
        : product.isLowStock
            ? ShadowBadgeVariant.warning
            : ShadowBadgeVariant.success;
    final stockLabel = product.isOutOfStock
        ? 'Out of stock'
        : '${product.stock} ${product.unit} in stock';
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ShadowTheme.screenPaddingH,
        0,
        ShadowTheme.screenPaddingH,
        24,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ShadowColors.muted,
                borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
              ),
              child: Text(product.emoji,
                  style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: ShadowTextStyles.h2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.isEmpty
                        ? 'Uncategorized'
                        : product.category,
                    style: ShadowTextStyles.bodyMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ShadowBadge(label: stockLabel, variant: variant),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _KeyStatsRow(product: product),
        const SizedBox(height: 24),
        const ShadowSectionLabel('Details'),
        const SizedBox(height: 12),
        ShadowCard(
          child: Column(
            children: [
              _DetailRow('Brand', product.brand.isEmpty ? '—' : product.brand),
              const ShadowDivider(),
              _DetailRow('SKU', product.sku.isEmpty ? '—' : product.sku),
              const ShadowDivider(),
              _DetailRow(
                'Barcode',
                product.barcode.isEmpty ? '—' : product.barcode,
              ),
              const ShadowDivider(),
              _DetailRow('Unit', product.unit.isEmpty ? '—' : product.unit),
              const ShadowDivider(),
              _DetailRow(
                'Alert threshold',
                '${product.alertThreshold} ${product.unit}',
              ),
              const ShadowDivider(),
              _DetailRow('Created', Formatters.dateTime(product.createdAt)),
              const ShadowDivider(),
              _DetailRow(
                'Last updated',
                Formatters.dateTime(product.updatedAt),
              ),
            ],
          ),
        ),
        if (product.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          const ShadowSectionLabel('Notes'),
          const SizedBox(height: 12),
          ShadowCard(
            child: Text(product.notes, style: ShadowTextStyles.body),
          ),
        ],
      ],
    );
  }
}

class _KeyStatsRow extends StatelessWidget {
  const _KeyStatsRow({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, Color accent) {
      return Expanded(
        child: ShadowStatCard(
          label: label,
          value: value,
          accent: accent,
        ),
      );
    }

    final margin = product.sellPrice - product.buyPrice;
    final marginPct = product.sellPrice > 0
        ? (margin / product.sellPrice * 100)
        : (product.buyPrice > 0 ? (margin / product.buyPrice * 100) : 0.0);
    final totalMargin = margin * product.stock;

    return Column(
      children: [
        Row(
          children: [
            cell(
              'Sell price',
              Formatters.currency(product.sellPrice),
              ShadowColors.accentSage,
            ),
            const SizedBox(width: ShadowTheme.gapCard),
            cell(
              'Buy price',
              Formatters.currency(product.buyPrice),
              ShadowColors.accentTerracotta,
            ),
            const SizedBox(width: ShadowTheme.gapCard),
            cell(
              'Value',
              Formatters.currency(product.inventoryValue),
              ShadowColors.accentDefault,
            ),
          ],
        ),
        const SizedBox(height: ShadowTheme.gapCard),
        Row(
          children: [
            Expanded(
              child: ShadowStatCard(
                label: 'Margin (per unit)',
                value: '${margin > 0 ? '+' : ''}${Formatters.currency(margin)}',
                sub: '${marginPct.toStringAsFixed(1)}%',
                accent: margin > 0
                    ? ShadowColors.accentSage
                    : margin < 0
                        ? ShadowColors.destructive
                        : ShadowColors.mutedForeground,
              ),
            ),
            const SizedBox(width: ShadowTheme.gapCard),
            Expanded(
              child: ShadowStatCard(
                label: 'Total margin',
                value: totalMargin > 0
                    ? '+${Formatters.currency(totalMargin)}'
                    : Formatters.currency(totalMargin),
                accent: totalMargin > 0
                    ? ShadowColors.accentSage
                    : totalMargin < 0
                        ? ShadowColors.destructive
                        : ShadowColors.mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: ShadowTextStyles.bodyMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: ShadowTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
