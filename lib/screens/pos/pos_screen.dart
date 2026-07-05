import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/transaction_type.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_animations.dart';
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

  /// Guards the stagger animation — set to false after first build so
  /// search/filter rebuilds don't replay it.
  bool _firstBuild = true;

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
          p.barcode.toLowerCase().contains(q));
    }
    return out.where((p) => p.isActive && p.stock > 0);
  }

  Future<void> _checkout() async {
    if (_cart.lines.isEmpty) return;
    if (!mounted) return;
    final result = await ShadowBottomSheet.show<_PaymentResult>(
      context: context,
      title: 'Payment',
      child: _PaymentSheet(
        total: _cart.total,
        subtotal: _cart.subtotal,
        initialDiscount: _cart.discount,
        initialTax: _cart.tax,
        customer: _cart.customer,
      ),
    );
    if (result == null || !mounted) return;
    final entityName = result.customer?.name ?? _cart.customerName;
    _cart.setCustomer(result.customer);
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
            costPriceAtTime: l.product.buyPrice,
          ),
      ];
      await context.read<TransactionProvider>().createTransaction(
            type: TransactionType.sale,
            items: drafts,
            discount: result.discount,
            taxAmount: result.tax,
            paymentMethod: result.method,
            paidAmount: result.paidAmount,
            entityId: result.customer?.id ?? '',
            entityName: entityName.isEmpty ? 'Walk-in' : entityName,
            movementReason: 'Sale',
          );
      if (!mounted) return;
      // Sale complete — strong haptic + state reset.
      HapticFeedback.mediumImpact();
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
    final isFirst = _firstBuild;
    if (_firstBuild) _firstBuild = false;

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
              // ─── Cart (top) ─────────────────────────────────────────
              _CartPanel(
                cart: _cart,
                onCheckout: _checkout,
              ),
              const SizedBox(height: 8),
              // ─── Product picker (bottom) ─────────────────────────────
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
                    physics: const BouncingScrollPhysics(),
                    scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
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
                          onTap: () => setState(() => _categoryFilter = null),
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
                            physics: const BouncingScrollPhysics(),
                            scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
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
                              final row = RepaintBoundary(
                                child: _PickerRow(
                                  product: p,
                                  inCart: _cart.contains(p.id),
                                  onTap: () {
                                    final live = products.byId(p.id);
                                    if (live == null) return;
                                    final existing = _cart.line(p.id);
                                    final next =
                                        (existing?.quantity ?? 0) + 1;
                                    if (next > live.stock) {
                                      _snack('Only ${live.stock} in stock');
                                      return;
                                    }
                                    _cart.addOrIncrement(p);
                                  },
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

// ─── Cart panel ──────────────────────────────────────────────────────

class _CartPanel extends StatefulWidget {
  const _CartPanel({required this.cart, required this.onCheckout});
  final CartState cart;
  final VoidCallback onCheckout;

  @override
  State<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<_CartPanel> {
  late final TextEditingController _customerCtrl;

  @override
  void initState() {
    super.initState();
    _customerCtrl = TextEditingController(text: widget.cart.customerName);
    widget.cart.addListener(_onCartChange);
  }

  @override
  void dispose() {
    widget.cart.removeListener(_onCartChange);
    _customerCtrl.dispose();
    super.dispose();
  }

  void _onCartChange() {
    if (_customerCtrl.text != widget.cart.customerName) {
      _customerCtrl.text = widget.cart.customerName;
    }
  }

  Future<void> _pickCustomer(BuildContext context) async {
    final customers = context.read<CustomerProvider>().all;
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
    if (selected != null) {
      widget.cart.setCustomer(selected);
    }
  }

  CartState get cart => widget.cart;

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
                      Icons.shopping_cart_outlined,
                      size: 18,
                      color: ShadowColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cart · ${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
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
                const SizedBox(height: 8),
                // Customer selector — type name or pick from list
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: ShadowColors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _customerCtrl,
                          style:
                              ShadowTextStyles.body.copyWith(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Walk-in customer',
                            hintStyle: ShadowTextStyles.body.copyWith(
                              fontSize: 13,
                              color: ShadowColors.mutedForeground,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: widget.cart.setCustomName,
                        ),
                      ),
                      Material(
                        color:
                            ShadowColors.muted.withValues(alpha: 0.5),
                        borderRadius:
                            BorderRadius.circular(ShadowTheme.radiusSm),
                        child: InkWell(
                          onTap: () => _pickCustomer(context),
                          borderRadius:
                              BorderRadius.circular(ShadowTheme.radiusSm),
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: ShadowColors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      physics: const BouncingScrollPhysics(),
                      scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
                      itemCount: cart.lines.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final line = cart.lines[i];
                        return _CartLineRow(
                          line: line,
                          onQty: (v) =>
                              cart.setQuantity(line.product.id, v),
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
                  _editableTotalsRow(
                    context,
                    'Discount',
                    cart.discount,
                    cart.setDiscount,
                    isNegative: true,
                  ),
                  const SizedBox(height: 4),
                  _editableTotalsRow(
                    context,
                    'Tax',
                    cart.tax,
                    cart.setTax,
                  ),
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
                    onPressed:
                        cart.itemCount == 0 ? null : widget.onCheckout,
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
        : ShadowTextStyles.body
            .copyWith(color: ShadowColors.mutedForeground);
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

  Widget _editableTotalsRow(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged, {
    bool isNegative = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ShadowTextStyles.body.copyWith(
              color: ShadowColors.mutedForeground,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final res = await ShadowBottomSheet.show<String>(
              context: context,
              title: 'Edit $label',
              child: _EditValueSheet(
                  initialValue: value, label: label),
            );
            if (res != null) {
              onChanged(double.tryParse(res) ?? 0);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ShadowColors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${isNegative ? '-' : ''}${Formatters.currency(value)}',
              style: ShadowTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: isNegative ? ShadowColors.destructive : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Edit value sheet ─────────────────────────────────────────────────

class _EditValueSheet extends StatefulWidget {
  const _EditValueSheet(
      {required this.initialValue, required this.label});
  final double initialValue;
  final String label;

  @override
  State<_EditValueSheet> createState() => _EditValueSheetState();
}

class _EditValueSheetState extends State<_EditValueSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.initialValue.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadowInput(
            label: widget.label,
            controller: _ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
          const SizedBox(height: 20),
          ShadowButton(
            label: 'Apply',
            expand: true,
            onPressed: () => Navigator.pop(context, _ctrl.text),
          ),
        ],
      ),
    );
  }
}

// ─── Cart line row ────────────────────────────────────────────────────

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
    final live = context.read<ProductProvider>().byId(line.product.id);
    final maxStock = live?.stock ?? line.product.stock;
    return Row(
      children: [
        Text(line.product.emoji, style: const TextStyle(fontSize: 20)),
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
              Text(
                '${Formatters.currency(line.unitPrice)} × ${line.quantity}'
                '  =  ${Formatters.currency(line.lineTotal)}',
                style:
                    ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        ShadowQuantityStepper(
          value: line.quantity,
          onChanged: onQty,
          min: 1,
          max: maxStock,
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
          Text(
            product.emoji.isEmpty ? '📦' : product.emoji,
            style: const TextStyle(fontSize: 20),
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
                  '${Formatters.currency(product.sellPrice)}'
                  '  ·  ${product.stock} ${product.unit}',
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

// ─── Payment result + sheet ───────────────────────────────────────────

class _PaymentResult {
  const _PaymentResult({
    required this.method,
    required this.paidAmount,
    required this.discount,
    required this.tax,
    this.customer,
  });
  final String method;
  final double paidAmount;
  final double discount;
  final double tax;
  final Customer? customer;
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.total,
    required this.subtotal,
    required this.initialDiscount,
    required this.initialTax,
    this.customer,
  });
  final double total;
  final double subtotal;
  final double initialDiscount;
  final double initialTax;
  final Customer? customer;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _method = AppConstants.paymentMethods.first;
  late final TextEditingController _paid;
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  late final ValueNotifier<double> _total;
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _paid =
        TextEditingController(text: widget.total.toStringAsFixed(2));
    _discount = TextEditingController(
        text: widget.initialDiscount.toStringAsFixed(2));
    _tax = TextEditingController(
        text: widget.initialTax.toStringAsFixed(2));
    _total = ValueNotifier(_computeTotal());
    _discount.addListener(_onTotalChanged);
    _tax.addListener(_onTotalChanged);
  }

  @override
  void dispose() {
    _paid.dispose();
    _discount.removeListener(_onTotalChanged);
    _tax.removeListener(_onTotalChanged);
    _discount.dispose();
    _tax.dispose();
    _total.dispose();
    super.dispose();
  }

  double _computeTotal() {
    final d = double.tryParse(_discount.text) ?? 0;
    final t = double.tryParse(_tax.text) ?? 0;
    final res = widget.subtotal - d + t;
    return res < 0 ? 0 : res;
  }

  void _onTotalChanged() {
    _total.value = _computeTotal();
  }

  Future<void> _pickCustomer() async {
    final customers = context.read<CustomerProvider>().all;
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _total,
              builder: (_, total, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total to pay', style: ShadowTextStyles.caption),
                  Text(
                    Formatters.currency(total),
                    style: ShadowTextStyles.h2
                        .copyWith(color: ShadowColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ShadowInput(
                    label: 'Discount',
                    controller: _discount,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    prefixIcon: Icons.remove_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadowInput(
                    label: 'Tax',
                    controller: _tax,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    prefixIcon: Icons.add_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
            Text('Customer', style: ShadowTextStyles.caption),
            const SizedBox(height: 8),
            Material(
              color: ShadowColors.input,
              borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
              child: InkWell(
                onTap: _pickCustomer,
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
                          _customer?.name ?? 'Walk-in customer',
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
            const SizedBox(height: 24),
            ShadowButton(
              label: 'Confirm payment',
              expand: true,
              icon: Icons.check_rounded,
              onPressed: () {
                final paid =
                    double.tryParse(_paid.text.trim()) ?? _computeTotal();
                final disc =
                    double.tryParse(_discount.text.trim()) ?? 0;
                final tax = double.tryParse(_tax.text.trim()) ?? 0;
                Navigator.of(context).pop(
                  _PaymentResult(
                    method: _method,
                    paidAmount: paid,
                    discount: disc,
                    tax: tax,
                    customer: _customer,
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
