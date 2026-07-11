import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/supplier.dart';
import '../../models/transaction_type.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

/// Record a purchase from a supplier. Buy prices are editable per-line
/// because a supplier's actual invoiced price may differ from the
/// product's stored buy_price.
class _Selected<T> {
  final T value;
  const _Selected(this.value);
}

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _cart = _PurchaseCart();
  final _searchCtrl = TextEditingController();
  String _search = '';

  /// Guards stagger animation — cleared after first build.
  bool _firstBuild = true;

  @override
  void dispose() {
    _cart.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Iterable<Product> _filter(List<Product> all) {
    if (_search.trim().isEmpty) return all;
    final q = _search.toLowerCase().trim();
    return all.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.sku.toLowerCase().contains(q) ||
        p.barcode.toLowerCase().contains(q));
  }

  Future<void> _confirm() async {
    if (_cart.lines.isEmpty) return;
    for (final l in _cart.lines) {
      if (l.buyPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.product.name}: buy price must be > 0')),
        );
        return;
      }
    }
    final ctx = context;
    final result = await ShadowBottomSheet.show<_PurchaseSubmit>(
      context: ctx,
      title: 'Complete purchase',
      child: _PurchaseSheet(total: _cart.total),
    );
    if (result == null || !ctx.mounted) return;
    try {
      final drafts = [
        for (final l in _cart.lines)
          makeItemDraft(
            productId: l.product.id,
            productName: l.product.name,
            productEmoji: l.product.emoji,
            productImagePath: l.product.imagePath,
            productUnit: l.product.unit,
            quantity: l.quantity,
            priceAtTime: l.buyPrice,
            costPriceAtTime: l.buyPrice,
          ),
      ];
      await ctx.read<TransactionProvider>().createTransaction(
            type: TransactionType.purchase,
            items: drafts,
            discount: 0,
            taxAmount: 0,
            paymentMethod: result.method,
            paidAmount: result.paidAmount,
            entityId: result.supplier?.id ?? '',
            entityName: result.supplier?.name ?? '',
            movementReason: 'Purchase',
          );
      if (!ctx.mounted) return;
      // Purchase complete — strong haptic.
      HapticFeedback.mediumImpact();
      await Future.wait([
        ctx.read<ProductProvider>().load(),
        ctx.read<SupplierProvider>().load(),
      ]);
      if (!ctx.mounted) return;
      _cart.clear();
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('Purchase recorded')));
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _firstBuild;
    if (_firstBuild) _firstBuild = false;

    return Consumer<ProductProvider>(
      builder: (context, products, _) {
        final list = _filter(products.all).toList();
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const ShadowPageHeader(
                title: 'Purchase',
                subtitle: 'Record supplier purchases',
              ),
              _PurchaseCartPanel(cart: _cart, onConfirm: _confirm),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ShadowTheme.screenPaddingH,
                ),
                child: ShadowSearchBar(
                  controller: _searchCtrl,
                  hint: 'Search products',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: products.isLoading && products.all.isEmpty
                    ? const SkeletonList.card(count: 4)
                    : list.isEmpty
                        ? const ShadowEmptyState(
                            title: 'No products',
                            subtitle:
                                'Add products first, then record purchases.',
                            icon: Icons.inventory_2_outlined,
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
                            padding: const EdgeInsets.fromLTRB(
                              ShadowTheme.screenPaddingH,
                              0,
                              ShadowTheme.screenPaddingH,
                              80,
                            ),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final row = RepaintBoundary(
                                child: _PickerRow(
                                  product: list[i],
                                  inCart: _cart.containsProduct(list[i].id),
                                  onTap: () => _cart.addOrIncrement(list[i]),
                                ),
                              );
                              if (!isFirst || i > 8) return row;
                              return ShadowAnimations.staggerItem(index: i, child: row);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Purchase cart ────────────────────────────────────────────────────

class _PurchaseCart extends ChangeNotifier {
  final Map<String, _PurchaseLine> _lines = {};

  List<_PurchaseLine> get lines => List.unmodifiable(_lines.values);
  int get itemCount => _lines.length;
  double get total =>
      _lines.values.fold<double>(0, (s, l) => s + l.lineTotal);

  bool containsProduct(String id) => _lines.containsKey(id);

  void addOrIncrement(Product p) {
    final existing = _lines[p.id];
    if (existing == null) {
      _lines[p.id] = _PurchaseLine(
        product: p,
        quantity: 1,
        buyPrice: p.buyPrice,
      );
    } else {
      _lines[p.id] = existing.copyWith(quantity: existing.quantity + 1);
    }
    notifyListeners();
  }

  void setQuantity(String id, int qty) {
    final existing = _lines[id];
    if (existing == null) return;
    if (qty <= 0) {
      _lines.remove(id);
    } else {
      _lines[id] = existing.copyWith(quantity: qty);
    }
    notifyListeners();
  }

  void setBuyPrice(String id, double price) {
    final existing = _lines[id];
    if (existing == null) return;
    _lines[id] = existing.copyWith(buyPrice: price < 0 ? 0 : price);
    notifyListeners();
  }

  void remove(String id) {
    _lines.remove(id);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}

class _PurchaseLine {
  const _PurchaseLine({
    required this.product,
    required this.quantity,
    required this.buyPrice,
  });
  final Product product;
  final int quantity;
  final double buyPrice;
  double get lineTotal => quantity * buyPrice;

  _PurchaseLine copyWith({int? quantity, double? buyPrice}) => _PurchaseLine(
        product: product,
        quantity: quantity ?? this.quantity,
        buyPrice: buyPrice ?? this.buyPrice,
      );
}

// ─── Cart panel ───────────────────────────────────────────────────────

class _PurchaseCartPanel extends StatelessWidget {
  const _PurchaseCartPanel({required this.cart, required this.onConfirm});
  final _PurchaseCart cart;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ShadowTheme.screenPaddingH,
          ),
          child: ShadowCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: ShadowColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Purchase · ${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                      style: ShadowTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (cart.itemCount > 0)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          cart.clear();
                        },
                        child: Text(
                          'Clear',
                          style: ShadowTextStyles.body.copyWith(
                            color: ShadowColors.destructive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (cart.lines.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tap a product below to add to this purchase.',
                    style: ShadowTextStyles.bodyMuted,
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
                      itemCount: cart.lines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final line = cart.lines[i];
                        return _PurchaseLineRow(
                          line: line,
                          onQty: (v) => cart.setQuantity(line.product.id, v),
                          onPrice: (v) => cart.setBuyPrice(line.product.id, v),
                          onRemove: () => cart.remove(line.product.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const ShadowDivider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Total', style: ShadowTextStyles.h4),
                      ),
                      Text(
                        Formatters.currency(cart.total),
                        style: ShadowTextStyles.h4
                            .copyWith(color: ShadowColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ShadowButton(
                    label: 'Confirm purchase',
                    icon: Icons.check_rounded,
                    expand: true,
                    onPressed: cart.itemCount == 0 ? null : onConfirm,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Purchase line row ────────────────────────────────────────────────

class _PurchaseLineRow extends StatelessWidget {
  const _PurchaseLineRow({
    required this.line,
    required this.onQty,
    required this.onPrice,
    required this.onRemove,
  });
  final _PurchaseLine line;
  final ValueChanged<int> onQty;
  final ValueChanged<double> onPrice;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        line.product.imagePath.isNotEmpty
            ? ClipRRect(
                clipBehavior: Clip.hardEdge,
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(line.product.imagePath),
                  width: 28,
                  height: 28,
                  cacheWidth: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Text(line.product.emoji, style: const TextStyle(fontSize: 20)),
                ),
              )
            : Text(line.product.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line.product.name,
                style: ShadowTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: _InlinePriceField(
                      value: line.buyPrice,
                      onChanged: onPrice,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '× ${line.quantity} = ${Formatters.currency(line.lineTotal)}',
                      style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        ShadowQuantityStepper(
          value: line.quantity,
          onChanged: onQty,
          min: 1,
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: ShadowColors.mutedForeground,
          onPressed: onRemove,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

// ─── Inline price field ───────────────────────────────────────────────

class _InlinePriceField extends StatefulWidget {
  const _InlinePriceField(
      {required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_InlinePriceField> createState() => _InlinePriceFieldState();
}

class _InlinePriceFieldState extends State<_InlinePriceField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value.toStringAsFixed(2));

  @override
  void didUpdateWidget(_InlinePriceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newText = widget.value.toStringAsFixed(2);
      if (_c.text != newText) {
        _c.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      style: ShadowTextStyles.body,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: (v) => widget.onChanged(double.tryParse(v) ?? 0),
      decoration: InputDecoration(
        prefixText: Formatters.currencySymbol,
        prefixStyle: ShadowTextStyles.bodyMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShadowTheme.radiusSm),
          borderSide:
              BorderSide(color: ShadowColors.border, width: 0.5),
        ),
      ),
    );
  }
}

Widget _avatarFallback(Product product) {
  return Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: ShadowColors.muted,
      borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
    ),
    child: Text(
      product.emoji.isEmpty ? '📦' : product.emoji,
      style: const TextStyle(fontSize: 20),
    ),
  );
}

// ─── Picker row ───────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.product,
    required this.inCart,
    required this.onTap,
  });
  final Product product;
  final bool inCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            clipBehavior: Clip.hardEdge,
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            child: product.imagePath.isNotEmpty
                ? Image.file(
                    File(product.imagePath),
                    width: 44,
                    height: 44,
                    cacheWidth: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(product),
                  )
                : _avatarFallback(product),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: ShadowTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Buy ${Formatters.currency(product.buyPrice)}'
                  '  ·  ${product.stock} ${product.unit} on hand',
                  style:
                      ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (inCart)
            Icon(
              Icons.check_circle_rounded,
              color: ShadowColors.accentSage,
              size: 20,
            )
          else
            Icon(
              Icons.add_circle_outline_rounded,
              color: ShadowColors.primary,
              size: 22,
            ),
        ],
      ),
    );
  }
}

// ─── Confirm sheet ────────────────────────────────────────────────────

class _PurchaseSubmit {
  const _PurchaseSubmit({
    required this.method,
    required this.paidAmount,
    this.supplier,
  });
  final String method;
  final double paidAmount;
  final Supplier? supplier;
}

class _PurchaseSheet extends StatefulWidget {
  const _PurchaseSheet({required this.total});
  final double total;

  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  late String _method;
  late final TextEditingController _paid;
  Supplier? _supplier;

  @override
  void initState() {
    super.initState();
    final methods = context.read<SettingsProvider>().settings.paymentMethods;
    _method = methods.isNotEmpty ? methods.first : 'cash';
    _paid =
        TextEditingController(text: widget.total.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _paid.dispose();
    super.dispose();
  }

  Future<void> _pickSupplier() async {
    final ctx = context;
    final suppliers = ctx.read<SupplierProvider>().all;
    if (suppliers.isEmpty) return;
    final selected = await ShadowBottomSheet.list<_Selected<Supplier?>>(
      context: ctx,
      title: 'Supplier',
      items: [
        const ShadowSheetItem(
          label: 'No supplier',
          value: _Selected<Supplier?>(null),
          icon: Icons.local_shipping_outlined,
        ),
        for (final s in suppliers)
          ShadowSheetItem(
            label: s.name,
            value: _Selected<Supplier?>(s),
            icon: Icons.local_shipping_rounded,
          ),
      ],
    );
    if (selected == null) return;
    if (!ctx.mounted) return;
    setState(() => _supplier = selected.value);
  }

  Widget _buildMethodChip(String m) {
    final selected = _method == m;
    final bg = selected ? ShadowColors.primary : ShadowColors.muted;
    final fg = selected ? ShadowColors.primaryFg : ShadowColors.foreground;
    return GestureDetector(
      onTap: () => setState(() => _method = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
          border: Border.all(
            color: selected ? ShadowColors.primary : ShadowColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          Formatters.capitalize(m),
          style: ShadowTextStyles.body.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methods = context.watch<SettingsProvider>().settings.paymentMethods;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total', style: ShadowTextStyles.caption),
            const SizedBox(height: 4),
            Text(
              Formatters.currency(widget.total),
              style:
                  ShadowTextStyles.h1.copyWith(color: ShadowColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Payment method', style: ShadowTextStyles.caption),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < methods.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      _buildMethodChip(methods[i]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShadowInput(
              label: 'Paid amount',
              controller: _paid,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              prefixIcon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: 16),
            Text('Supplier', style: ShadowTextStyles.caption),
            const SizedBox(height: 8),
            Material(
              color: ShadowColors.input,
              borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
              child: InkWell(
                onTap: _pickSupplier,
                borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(ShadowTheme.radiusMd),
                    border: Border.all(
                        color: ShadowColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _supplier?.name ?? 'No supplier',
                          style: ShadowTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ShadowColors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShadowButton(
              label: 'Confirm purchase',
              expand: true,
              icon: Icons.check_rounded,
              onPressed: () {
                final paid =
                    double.tryParse(_paid.text.trim()) ?? widget.total;
                Navigator.of(context).pop(
                  _PurchaseSubmit(
                    method: _method,
                    paidAmount: paid,
                    supplier: _supplier,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
