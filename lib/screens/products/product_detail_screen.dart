import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:uuid/uuid.dart';

import '../../models/product.dart';
import '../../models/product_variant.dart';
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

  Future<void> _restoreProduct(BuildContext context, Product p) async {
    final ok = await ShadowConfirmDialog.show(
      context,
      title: 'Restore product?',
      message: '"${p.name}" will be restored to the active catalog.',
      confirmLabel: 'Restore',
    );
    if (!ok) return;
    if (!context.mounted) return;
    await context.read<ProductProvider>().restoreProduct(p.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _duplicateProduct(BuildContext context, Product p) async {
    await context.read<ProductProvider>().duplicateProduct(p.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product duplicated'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showQrCode(BuildContext context, Product p) {
    final barcode = p.barcode.isNotEmpty ? p.barcode : p.id;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShadowColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ShadowTheme.radiusLg)),
        title: Text(Formatters.titleCase(p.name), style: ShadowTextStyles.h4, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: barcode,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            Text(barcode, style: ShadowTextStyles.bodyMuted, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          ShadowButton(label: 'Close', variant: ShadowButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
        ],
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
              BoxDecoration(gradient: ShadowColors.pageBackground),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme:
                  IconThemeData(color: ShadowColors.foreground),
              actions: [
                if (p != null) ...[
                  IconButton(
                    tooltip: 'QR Code',
                    icon: const Icon(Icons.qr_code_rounded),
                    onPressed: () => _showQrCode(context, p),
                  ),
                  if (p.isActive) ...[
                    IconButton(
                      tooltip: 'Duplicate',
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => _duplicateProduct(context, p),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openEdit(context, p),
                    ),
                    IconButton(
                      tooltip: 'Archive',
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: () => _confirmDelete(context, p),
                    ),
                  ] else ...[
                    IconButton(
                      tooltip: 'Restore',
                      icon: const Icon(Icons.unarchive_rounded),
                      onPressed: () => _restoreProduct(context, p),
                    ),
                  ],
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

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.product});
  final Product product;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  late final ProductProvider _provider;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _provider = context.read<ProductProvider>();
    _provider.loadVariants(widget.product.id);
  }

  static Widget _emojiBubble(Product p) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ShadowColors.muted,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
      ),
      child: Text(
        p.emoji.isEmpty ? '📦' : p.emoji,
        style: const TextStyle(fontSize: 40),
      ),
    );
  }

  Future<void> _addVariant() {
    final product = widget.product;
    final nameCtl = TextEditingController();
    final skuCtl = TextEditingController();
    final buyCtl = TextEditingController();
    final sellCtl = TextEditingController();
    final stockCtl = TextEditingController();
    final attrCtl = TextEditingController();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShadowColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ShadowTheme.radiusLg)),
        title: Text('Add Variant', style: ShadowTextStyles.h4),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _variantField(nameCtl, 'Variant name (e.g. Small, Red)', 'Name'),
              const SizedBox(height: 8),
              _variantField(skuCtl, 'SKU', 'SKU'),
              const SizedBox(height: 8),
              _variantField(buyCtl, 'Buy price', 'Buy Price'),
              const SizedBox(height: 8),
              _variantField(sellCtl, 'Sell price', 'Sell Price'),
              const SizedBox(height: 8),
              _variantField(stockCtl, 'Stock quantity', 'Stock'),
              const SizedBox(height: 8),
              _variantField(attrCtl, 'color:Red;size:M', 'Attributes'),
            ],
          ),
        ),
        actions: [
          ShadowButton(
            label: 'Cancel',
            variant: ShadowButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
          ShadowButton(
            label: 'Add',
            onPressed: () async {
              final now = DateTime.now();
              final v = ProductVariant(
                id: _uuid.v4(),
                productId: product.id,
                name: nameCtl.text.trim(),
                sku: skuCtl.text.trim(),
                buyPrice: double.tryParse(buyCtl.text) ?? 0,
                sellPrice: double.tryParse(sellCtl.text) ?? 0,
                stock: int.tryParse(stockCtl.text) ?? 0,
                attributes: ProductVariant.decodeAttributes(attrCtl.text.trim()),
                createdAt: now,
                updatedAt: now,
              );
              await _provider.addVariant(v);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editVariant(ProductVariant v) {
    final nameCtl = TextEditingController(text: v.name);
    final skuCtl = TextEditingController(text: v.sku);
    final buyCtl = TextEditingController(text: v.buyPrice.toString());
    final sellCtl = TextEditingController(text: v.sellPrice.toString());
    final stockCtl = TextEditingController(text: v.stock.toString());

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShadowColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ShadowTheme.radiusLg)),
        title: Text('Edit Variant', style: ShadowTextStyles.h4),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _variantField(nameCtl, 'Variant name', 'Name'),
              const SizedBox(height: 8),
              _variantField(skuCtl, 'SKU', 'SKU'),
              const SizedBox(height: 8),
              _variantField(buyCtl, 'Buy price', 'Buy Price'),
              const SizedBox(height: 8),
              _variantField(sellCtl, 'Sell price', 'Sell Price'),
              const SizedBox(height: 8),
              _variantField(stockCtl, 'Stock quantity', 'Stock'),
            ],
          ),
        ),
        actions: [
          ShadowButton(
            label: 'Cancel',
            variant: ShadowButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
          ShadowButton(
            label: 'Save',
            onPressed: () async {
              final updated = v.copyWith(
                name: nameCtl.text.trim(),
                sku: skuCtl.text.trim(),
                buyPrice: double.tryParse(buyCtl.text) ?? v.buyPrice,
                sellPrice: double.tryParse(sellCtl.text) ?? v.sellPrice,
                stock: int.tryParse(stockCtl.text) ?? v.stock,
              );
              await _provider.updateVariant(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVariant(ProductVariant v) async {
    final ok = await ShadowConfirmDialog.show(
      context,
      title: 'Delete variant?',
      message: '"${v.name}" will be removed permanently.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await _provider.deleteVariant(v.id, v.productId);
  }

  static Widget _variantField(TextEditingController ctl, String hint, String label) {
    return TextField(
      controller: ctl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variant = !product.isActive
        ? ShadowBadgeVariant.muted
        : product.isOutOfStock
            ? ShadowBadgeVariant.danger
            : product.isLowStock
                ? ShadowBadgeVariant.warning
                : ShadowBadgeVariant.success;
    final stockLabel = !product.isActive
        ? 'Archived'
        : product.isOutOfStock
            ? 'Out of stock'
            : '${product.stock} ${product.unit} in stock';
    return ListView(
      physics: const BouncingScrollPhysics(),
      scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
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
            ClipRRect(
              clipBehavior: Clip.hardEdge,
              borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
              child: product.imagePath.isNotEmpty
                  ? Image.file(
                      File(product.imagePath),
                      width: 72,
                      height: 72,
                      cacheWidth: 144,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _emojiBubble(product),
                    )
                  : _emojiBubble(product),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.titleCase(product.name),
                    style: ShadowTextStyles.h2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.isEmpty
                        ? 'Uncategorized'
                        : Formatters.titleCase(product.category),
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
        _VariantsSection(product: product, onAdd: _addVariant, onEdit: _editVariant, onDelete: _deleteVariant),
        const SizedBox(height: 24),
        const ShadowSectionLabel('Details'),
        const SizedBox(height: 12),
        ShadowCard(
          child: Column(
            children: [
              _DetailRow(
                'Brand',
                product.brand.isEmpty ? '—' : Formatters.titleCase(product.brand),
              ),
              const ShadowDivider(),
              _DetailRow('SKU', product.sku.isEmpty ? '—' : product.sku.toUpperCase()),
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
              _DetailRow(
                'QR Code',
                product.barcode.isNotEmpty ? product.barcode : product.id,
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
              'Sale',
              Formatters.currency(product.sellPrice),
              ShadowColors.accentSage,
            ),
            const SizedBox(width: ShadowTheme.gapCard),
            cell(
              'Cost',
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
                label: 'Margin / Unit',
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
                label: 'Total Margin',
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

class _VariantsSection extends StatelessWidget {
  const _VariantsSection({
    required this.product,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onAdd;
  final void Function(ProductVariant) onEdit;
  final void Function(ProductVariant) onDelete;

  @override
  Widget build(BuildContext context) {
    final variants = context.watch<ProductProvider>().variantsForProduct(product.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ShadowSectionLabel('Variants'),
            const Spacer(),
            if (product.isActive)
              GestureDetector(
                onTap: onAdd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Icon(Icons.add_circle_outline, size: 20, color: ShadowColors.accentDefault),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (variants.isEmpty)
          ShadowCard(
            child: Text(
              product.isActive ? 'No variants. Tap + to add one.' : 'Archived products cannot have variants.',
              style: ShadowTextStyles.bodyMuted,
            ),
          )
        else
          ShadowCard(
            child: Column(
              children: variants.map((v) {
                final stockLabel = v.isOutOfStock
                    ? 'Out of stock'
                    : '${v.stock} in stock';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: ShadowTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '${Formatters.currency(v.sellPrice)}  |  $stockLabel',
                              style: ShadowTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      if (product.isActive) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => onEdit(v),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: ShadowColors.mutedForeground,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => onDelete(v),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: ShadowColors.destructive,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
              textAlign: TextAlign.left,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
