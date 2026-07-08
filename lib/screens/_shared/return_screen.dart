import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../models/transaction_item.dart';
import '../../models/transaction_type.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/entity_helpers.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

enum ReturnKind { sales, purchase }

class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key, required this.kind});
  final ReturnKind kind;

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  Transaction? _originalTxn;
  final Map<String, int> _returnQtys = {};
  final Map<String, int> _alreadyReturnedQtys = {};
  final _reasonCtrl = TextEditingController();
  final _refundCtrl = TextEditingController();
  bool _saving = false;

  bool get _isSales => widget.kind == ReturnKind.sales;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _refundCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTransaction() async {
    final provider = context.read<TransactionProvider>();
    final txns = _isSales
        ? provider.all.where((t) => t.type == TransactionType.sale).toList()
        : provider.all
            .where((t) => t.type == TransactionType.purchase)
            .toList();

    if (txns.isEmpty) {
      _snack('No past ${_isSales ? 'sales' : 'purchases'} found.');
      return;
    }

    final picked = await ShadowBottomSheet.list<Transaction>(
      context: context,
      title: 'Select Original ${_isSales ? 'Sale' : 'Purchase'}',
      items: [
        for (final t in txns)
          ShadowSheetItem(
            label:
                '${Formatters.date(t.createdAt)} · ${resolveEntityName(t.entityName)} · ${Formatters.currency(t.totalAmount)}',
            value: t,
          ),
      ],
    );

    if (picked != null) {
      // Find all subsequent returns for this transaction to calculate limits
      final returns = provider.all.where((t) =>
          (t.type == TransactionType.salesReturn ||
              t.type == TransactionType.purchaseReturn) &&
          t.originalTransactionId == picked.id);

      final returnedMap = <String, int>{};
      for (final ret in returns) {
        for (final item in ret.items) {
          returnedMap[item.productId] =
              (returnedMap[item.productId] ?? 0) + item.quantity;
        }
      }

      setState(() {
        _originalTxn = picked;
        _returnQtys.clear();
        _alreadyReturnedQtys.clear();
        _alreadyReturnedQtys.addAll(returnedMap);
        for (final item in picked.items) {
          _returnQtys[item.productId] = 0;
        }
        _refundCtrl.text = '0';
      });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    if (_originalTxn == null) {
      _snack('Please select an original transaction first.');
      return;
    }

    final itemsToReturn = _originalTxn!.items.where((it) {
      final qty = _returnQtys[it.productId] ?? 0;
      return qty > 0;
    }).toList();

    if (itemsToReturn.isEmpty) {
      _snack('Please select at least one item and quantity to return.');
      return;
    }

    setState(() => _saving = true);
    try {
      final drafts = itemsToReturn.map((it) {
        final qty = _returnQtys[it.productId]!;
        return makeItemDraft(
          productId: it.productId,
          productName: it.productName,
          productEmoji: it.productEmoji,
          productImagePath: it.productImagePath,
          productUnit: it.productUnit,
          quantity: qty,
          priceAtTime: it.priceAtTime,
          costPriceAtTime: it.costPriceAtTime,
          discount: 0, 
          tax: 0,
        );
      }).toList();

      await context.read<TransactionProvider>().createTransaction(
            type: _isSales
                ? TransactionType.salesReturn
                : TransactionType.purchaseReturn,
            items: drafts,
            discount: 0,
            taxAmount: 0,
            paymentMethod: _originalTxn!.paymentMethod,
            paidAmount: double.tryParse(_refundCtrl.text.trim()) ?? 0,
            entityId: _originalTxn!.entityId,
            entityName: _originalTxn!.entityName,
            originalTransactionId: _originalTxn!.id,
            notes: _reasonCtrl.text.trim(),
            movementReason: _reasonCtrl.text.trim().isEmpty
                ? (_isSales ? 'Sales return' : 'Purchase return')
                : _reasonCtrl.text.trim(),
          );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await context.read<ProductProvider>().load();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!mounted) return;
      _snack(_isSales ? 'Sales return recorded' : 'Purchase return recorded');
    } catch (e) {
      if (mounted) _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
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
                  ? 'Return items from a past sale'
                  : 'Return items to a supplier',
            ),
            const ShadowSectionLabel('Original Transaction'),
            const SizedBox(height: 8),
            _TxnPickerField(txn: _originalTxn, onTap: _pickTransaction),
            if (_originalTxn != null) ...[
              const SizedBox(height: 20),
              const ShadowSectionLabel('Items to Return'),
              const SizedBox(height: 8),
              for (final item in _originalTxn!.items) ...[
                _ReturnItemRow(
                  item: item,
                  qty: _returnQtys[item.productId] ?? 0,
                  alreadyReturnedQty: _alreadyReturnedQtys[item.productId] ?? 0,
                  onQtyChanged: (v) =>
                      setState(() => _returnQtys[item.productId] = v),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 20),
              ShadowInput(
                label: 'Refund amount (0 = store credit)',
                controller: _refundCtrl,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                prefixIcon: Icons.attach_money_rounded,
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
          ],
        ),
      ),
    );
  }
}

class _TxnPickerField extends StatelessWidget {
  const _TxnPickerField({required this.txn, required this.onTap});
  final Transaction? txn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined,
              color: ShadowColors.mutedForeground, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  txn == null
                      ? 'Pick original transaction'
                      : 'Txn: ${txn!.id.substring(0, 8)}',
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: txn == null
                        ? ShadowColors.mutedForeground
                        : ShadowColors.foreground,
                  ),
                ),
                if (txn != null)
                  Text(
                    '${Formatters.dateTime(txn!.createdAt)} · ${resolveEntityName(txn!.entityName)}',
                    style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: ShadowColors.mutedForeground),
        ],
      ),
    );
  }
}

class _ReturnItemRow extends StatelessWidget {
  const _ReturnItemRow({
    required this.item,
    required this.qty,
    required this.alreadyReturnedQty,
    required this.onQtyChanged,
  });
  final TransactionItem item;
  final int qty;
  final int alreadyReturnedQty;
  final ValueChanged<int> onQtyChanged;

  @override
  Widget build(BuildContext context) {
    final remaining = (item.quantity - alreadyReturnedQty).clamp(0, item.quantity);
    return ShadowCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          item.productImagePath.isNotEmpty
              ? ClipRRect(
                  clipBehavior: Clip.hardEdge,
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(item.productImagePath),
                    width: 28,
                    height: 28,
                    cacheWidth: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Text(item.productEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                )
              : Text(item.productEmoji.isEmpty ? '📦' : item.productEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.productName,
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Original: ${item.quantity} · Returned: $alreadyReturnedQty',
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          ShadowQuantityStepper(
            value: qty,
            onChanged: onQtyChanged,
            min: 0,
            max: remaining,
          ),
        ],
      ),
    );
  }
}
