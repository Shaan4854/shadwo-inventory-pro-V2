import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/transaction_type.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../_shared/cart_state.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _cart = CartState();
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _categoryFilter;

  @override
  void dispose() {
    _cart.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Iterable<Product> _filter(List<Product> all) {
    Iterable<Product> out = all;
    if (_categoryFilter != null) {
      out = out.where((p) => p.category == _categoryFilter);
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      out = out.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.barcode.contains(q));
    }
    return out.where((p) => p.stock > 0);
  }

  Future<void> _checkout() async {
    if (_cart.lines.isEmpty) return;
    final products = context.read<ProductProvider>();
    // Validate stock — cart may be stale if user was away a while.
    for (final line in _cart.lines) {
      final live = products.byId(line.product.id);
      if (live == null || live.stock < line.quantity) {
        _snack('Not enough stock for ${line.product.name}');
        return;
      }
    }
    if (!mounted) return;
    final result = await ShadowBottomSheet.show<_PaymentResult>(
      context: context,
      title: 'Payment',
      child: _PaymentSheet(total: _cart.total),
    );
    if (result == null || !mounted) return;
    try {
      final drafts = [
        for (final l in _cart.lines)
          makeItemDraft(
            productId: l.product.id,
            productName: l.product.name,
            productEmoji: l.product.emoji,
            productUnit: l.product.unit,
            quantity: l.quantity,
            priceAtTime: l.unitPrice,
          ),
      ];
      await context.read<TransactionProvider>().createTransaction(
            type: TransactionType.sale,
            items: drafts,
            discount: _cart.discount,
            taxAmount: _cart.tax,
            paymentMethod: result.method,
            paidAmount: result.paidAmount,
            entityId: result.customer?.id ?? '',
            entityName: result.customer?.name ?? '',
            movementReason: 'Sale',
          );
      if (!mounted) return;
      await context.read<ProductProvider>().load();
      if (!mounted) return;
      _cart.clear();
      _snack('Sale recorded');
    } catch (e) {
      if (mounted) _snack('Sale failed: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, products, _) {
        final categories = products.all
            .map((p) => p.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final filtered = _filter(products.all).toList();
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const ShadowPageHeader(
                title: 'Sell',
                subtitle: 'Point of sale',
              ),
              // ─── Cart (top) ─────────────────────────
              _CartPanel(
                cart: _cart,
                onCheckout: _checkout,
              ),
              const SizedBox(height: 8),
              // ─── Product picker (bottom) ────────────
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
              if (categories.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ShadowTheme.screenPaddingH,
                    ),
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return ShadowFilterChip(
                          label: 'All',
                          selected: _categoryFilter == null,
                          onTap: () =>
                              setState(() => _categoryFilter = null),
                        );
                      }
                      final c = categories[i - 1];
                      return ShadowFilterChip(
                        label: c,
                        selected: _categoryFilter == c,
                        onTap: () => setState(() => _categoryFilter = c),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: products.isLoading && products.all.isEmpty
                    ? const SkeletonList.card(count: 4)
                    : filtered.isEmpty
                        ? const ShadowEmptyState(
                            title: 'No products in stock',
                            subtitle:
                                'Nothing available for sale matching your filter.',
                            icon: Icons.storefront_outlined,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              ShadowTheme.screenPaddingH,
                              0,
                              ShadowTheme.screenPaddingH,
                              80,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              return _PickerRow(
                                product: p,
                                inCart: _cart.contains(p.id),
                                onTap: () {
                                  final live = products.byId(p.id);
                                  if (live == null) return;
                                  final existing = _cart.line(p.id);
                                  final next = (existing?.quantity ?? 0) + 1;
                                  if (next > live.stock) {
                                    _snack('Only ${live.stock} in stock');
                                    return;
                                  }
                                  _cart.addOrIncrement(p);
                                },
                              );
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

// ─── Cart panel ─────────────────────────────────────────────────

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.cart, required this.onCheckout});
  final CartState cart;
  final VoidCallback onCheckout;

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
                    const Icon(Icons.shopping_cart_outlined,
                        size: 18, color: ShadowColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Cart · ${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                      style: ShadowTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (cart.itemCount > 0)
                      TextButton(
                        onPressed: cart.clear,
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
                    'Add products from the list to start a sale.',
                    style: ShadowTextStyles.bodyMuted,
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: cart.lines.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final line = cart.lines[i];
                        return _CartLineRow(
                          line: line,
                          onQty: (v) => cart.setQuantity(line.product.id, v),
                          onRemove: () => cart.remove(line.product.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const ShadowDivider(),
                  const SizedBox(height: 8),
                  _totalsRow('Subtotal', Formatters.currency(cart.subtotal)),
                  const SizedBox(height: 4),
                  _totalsRow('Discount', '- ${Formatters.currency(cart.discount)}'),
                  const SizedBox(height: 4),
                  _totalsRow('Tax', Formatters.currency(cart.tax)),
                  const SizedBox(height: 6),
                  _totalsRow(
                    'Total',
                    Formatters.currency(cart.total),
                    bold: true,
                  ),
                  const SizedBox(height: 12),
                  ShadowButton(
                    label: 'Checkout',
                    icon: Icons.point_of_sale_rounded,
                    expand: true,
                    onPressed: cart.itemCount == 0 ? null : onCheckout,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _totalsRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? ShadowTextStyles.h4
        : ShadowTextStyles.body.copyWith(color: ShadowColors.mutedForeground);
    final valueStyle = bold
        ? ShadowTextStyles.h4.copyWith(color: ShadowColors.primary)
        : ShadowTextStyles.body.copyWith(fontWeight: FontWeight.w600);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.line,
    required this.onQty,
    required this.onRemove,
  });
  final CartLine line;
  final ValueChanged<int> onQty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(line.product.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line.product.name,
                style: ShadowTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${Formatters.currency(line.unitPrice)} × ${line.quantity}  =  ${Formatters.currency(line.lineTotal)}',
                style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ShadowQuantityStepper(
          value: line.quantity,
          onChanged: onQty,
          min: 1,
          max: line.product.stock,
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: ShadowColors.mutedForeground,
          onPressed: onRemove,
        ),
      ],
    );
  }
}

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
          Text(product.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${Formatters.currency(product.sellPrice)}  ·  ${product.stock} ${product.unit}',
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (inCart)
            const Icon(Icons.check_circle_rounded,
                color: ShadowColors.accentSage, size: 20)
          else
            const Icon(Icons.add_circle_outline_rounded,
                color: ShadowColors.primary, size: 22),
        ],
      ),
    );
  }
}

// ─── Payment sheet ──────────────────────────────────────────────

class _PaymentResult {
  const _PaymentResult({
    required this.method,
    required this.paidAmount,
    this.customer,
  });
  final String method;
  final double paidAmount;
  final Customer? customer;
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.total});
  final double total;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _method = AppConstants.paymentMethods.first;
  late final TextEditingController _paid;
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _paid = TextEditingController(text: widget.total.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _paid.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final customers = context.read<CustomerProvider>().all;
    if (customers.isEmpty) return;
    final selected = await ShadowBottomSheet.list<Customer?>(
      context: context,
      title: 'Customer',
      items: [
        const ShadowSheetItem(
          label: 'Walk-in customer',
          value: null,
          icon: Icons.person_outline_rounded,
        ),
        for (final c in customers)
          ShadowSheetItem(
            label: c.name,
            value: c,
            icon: Icons.person_rounded,
          ),
      ],
    );
    setState(() => _customer = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Total', style: ShadowTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(widget.total),
            style: ShadowTextStyles.h1.copyWith(color: ShadowColors.primary),
          ),
          const SizedBox(height: 20),
          Text('Payment method', style: ShadowTextStyles.caption),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final m in AppConstants.paymentMethods) ...[
                Expanded(
                  child: ShadowFilterChip(
                    label: m[0].toUpperCase() + m.substring(1),
                    selected: _method == m,
                    onTap: () => setState(() => _method = m),
                  ),
                ),
                if (m != AppConstants.paymentMethods.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),
          ShadowInput(
            label: 'Paid amount',
            controller: _paid,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            prefixIcon: Icons.attach_money_rounded,
          ),
          const SizedBox(height: 16),
          Text('Customer', style: ShadowTextStyles.caption),
          const SizedBox(height: 8),
          Material(
            color: ShadowColors.input,
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            child: InkWell(
              onTap: _pickCustomer,
              borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(ShadowTheme.radiusMd),
                  border: Border.all(color: ShadowColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _customer?.name ?? 'Walk-in customer',
                        style: ShadowTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: ShadowColors.mutedForeground),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ShadowButton(
            label: 'Confirm payment',
            expand: true,
            icon: Icons.check_rounded,
            onPressed: () {
              final paid = double.tryParse(_paid.text.trim()) ?? widget.total;
              Navigator.of(context).pop(
                _PaymentResult(
                  method: _method,
                  paidAmount: paid,
                  customer: _customer,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
