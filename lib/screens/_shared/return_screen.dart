import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/supplier.dart';
import '../../models/transaction_type.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

enum ReturnKind { sales, purchase }

/// Return-a-product form. Same UI for sales & purchase returns, only the
/// entity picker + `TransactionType` differ.
class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key, required this.kind});
  final ReturnKind kind;

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  Product? _product;
  int _qty = 1;
  double _refund = 0;
  Customer? _customer;
  Supplier? _supplier;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  bool get _isSales => widget.kind == ReturnKind.sales;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final list = context.read<ProductProvider>().all;
    if (list.isEmpty) return;
    final picked = await ShadowBottomSheet.list<Product>(
      context: context,
      title: 'Pick product',
      items: [
        for (final p in list)
          ShadowSheetItem(
            label: '${p.emoji}  ${p.name}',
            value: p,
          ),
      ],
    );
    if (picked != null) {
      setState(() {
        _product = picked;
        _refund = picked.sellPrice * _qty;
      });
    }
  }

  Future<void> _pickCustomer() async {
    final list = context.read<CustomerProvider>().all;
    if (list.isEmpty) return;
    final picked = await ShadowBottomSheet.list<Customer?>(
      context: context,
      title: 'Customer',
      items: [
        const ShadowSheetItem(label: 'None', value: null),
        for (final c in list)
          ShadowSheetItem(label: c.name, value: c),
      ],
    );
    setState(() => _customer = picked);
  }

  Future<void> _pickSupplier() async {
    final list = context.read<SupplierProvider>().all;
    if (list.isEmpty) return;
    final picked = await ShadowBottomSheet.list<Supplier?>(
      context: context,
      title: 'Supplier',
      items: [
        const ShadowSheetItem(label: 'None', value: null),
        for (final s in list)
          ShadowSheetItem(label: s.name, value: s),
      ],
    );
    setState(() => _supplier = picked);
  }

  Future<void> _save() async {
    if (_product == null || _qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a product and enter a quantity.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final unit = _refund <= 0
          ? (_isSales ? _product!.sellPrice : _product!.buyPrice)
          : (_refund / _qty);
      final drafts = [
        makeItemDraft(
          productId: _product!.id,
          productName: _product!.name,
          productEmoji: _product!.emoji,
          productUnit: _product!.unit,
          quantity: _qty,
          priceAtTime: unit,
        ),
      ];
      await context.read<TransactionProvider>().createTransaction(
            type: _isSales
                ? TransactionType.salesReturn
                : TransactionType.purchaseReturn,
            items: drafts,
            discount: 0,
            taxAmount: 0,
            paymentMethod: 'cash',
            paidAmount: unit * _qty,
            entityId: _isSales
                ? (_customer?.id ?? '')
                : (_supplier?.id ?? ''),
            entityName: _isSales
                ? (_customer?.name ?? '')
                : (_supplier?.name ?? ''),
            notes: _reasonCtrl.text.trim(),
            movementReason: _reasonCtrl.text.trim().isEmpty
                ? (_isSales ? 'Sales return' : 'Purchase return')
                : _reasonCtrl.text.trim(),
          );
      if (!mounted) return;
      await context.read<ProductProvider>().load();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isSales ? 'Sales return recorded' : 'Purchase return recorded'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: ShadowColors.foreground),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            ShadowTheme.screenPaddingH,
            0,
            ShadowTheme.screenPaddingH,
            24,
          ),
          children: [
            ShadowPageHeader(
              title: _isSales ? 'Sales Return' : 'Purchase Return',
              subtitle: _isSales
                  ? 'Take stock back, refund customer'
                  : 'Send stock back to supplier',
            ),
            const ShadowSectionLabel('Product'),
            const SizedBox(height: 8),
            _ProductField(product: _product, onTap: _pickProduct),
            const SizedBox(height: 20),
            const ShadowSectionLabel('Quantity'),
            const SizedBox(height: 8),
            ShadowCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_qty ${_product?.unit ?? 'unit'}${_qty == 1 ? '' : 's'}',
                      style: ShadowTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ShadowQuantityStepper(
                    value: _qty,
                    onChanged: (v) {
                      setState(() {
                        _qty = v;
                        if (_product != null) {
                          _refund = _product!.sellPrice * v;
                        }
                      });
                    },
                    min: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const ShadowSectionLabel('Refund amount'),
            const SizedBox(height: 8),
            _RefundField(
              value: _refund,
              onChanged: (v) => setState(() => _refund = v),
            ),
            const SizedBox(height: 20),
            ShadowSectionLabel(_isSales ? 'Customer' : 'Supplier'),
            const SizedBox(height: 8),
            _EntityField(
              label: _isSales
                  ? _customer?.name ?? 'None'
                  : _supplier?.name ?? 'None',
              onTap: _isSales ? _pickCustomer : _pickSupplier,
            ),
            const SizedBox(height: 20),
            ShadowInput(
              label: 'Reason (optional)',
              controller: _reasonCtrl,
              hint: 'e.g. Defective, Wrong item',
            ),
            const SizedBox(height: 24),
            ShadowButton(
              label: _isSales
                  ? 'Record sales return'
                  : 'Record purchase return',
              icon: Icons.check_rounded,
              expand: true,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductField extends StatelessWidget {
  const _ProductField({required this.product, required this.onTap});
  final Product? product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ShadowColors.muted,
              borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            ),
            child: Text(
              product?.emoji ?? '📦',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product?.name ?? 'Pick a product',
              style: ShadowTextStyles.body.copyWith(
                color: product == null
                    ? ShadowColors.mutedForeground
                    : ShadowColors.foreground,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: ShadowColors.mutedForeground),
        ],
      ),
    );
  }
}

class _RefundField extends StatefulWidget {
  const _RefundField({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_RefundField> createState() => _RefundFieldState();
}

class _RefundFieldState extends State<_RefundField> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _RefundField old) {
    super.didUpdateWidget(old);
    if (widget.value != double.tryParse(_c.text)) {
      _c.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Text(
            Formatters.currency(0).replaceAll('0.00', ''),
            style: ShadowTextStyles.bodyMuted,
          ),
          Expanded(
            child: TextField(
              controller: _c,
              style: ShadowTextStyles.h4,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (v) =>
                  widget.onChanged(double.tryParse(v) ?? 0),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntityField extends StatelessWidget {
  const _EntityField({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded,
              color: ShadowColors.mutedForeground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: ShadowTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: ShadowColors.mutedForeground),
        ],
      ),
    );
  }
}
