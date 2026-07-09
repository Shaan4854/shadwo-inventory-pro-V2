import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../models/supplier.dart';
import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/record_payment_sheet.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../_shared/entity_form_sheet.dart';
import '../transactions/transaction_detail_screen.dart';

class SupplierDetailScreen extends StatefulWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});
  final String supplierId;

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  Future<void> _confirmDelete(Supplier s) async {
    final ok = await ShadowConfirmDialog.show(
      context,
      title: 'Delete supplier?',
      message: '"${s.name}" will be removed.',
      danger: true,
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    final provider = context.read<SupplierProvider>();
    final navigator = Navigator.of(context);
    await provider.deleteSupplier(s.id);
    if (mounted) navigator.pop();
  }

  void _openEdit(Supplier s) {
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(
        page: EntityFormSheet(kind: EntityKind.supplier, supplier: s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupplierProvider, TransactionProvider>(
      builder: (context, suppliers, txns, _) {
        final s = suppliers.byId(widget.supplierId);
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
                if (s != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _openEdit(s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _confirmDelete(s),
                  ),
                ],
              ],
            ),
            body: s == null
                ? const ShadowEmptyState(
                    title: 'Supplier not found',
                    icon: Icons.help_outline_rounded,
                  )
                : _Body(
                    supplier: s,
                    allTxns: txns.all
                        .where((t) =>
                            (t.type == TransactionType.purchase ||
                             t.type == TransactionType.purchaseReturn ||
                             t.type == TransactionType.supplierPayment) &&
                            t.entityId == s.id)
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
                  ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.supplier, required this.allTxns});
  final Supplier supplier;
  final List<Transaction> allTxns;

  void _recordPayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ShadowColors.card,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ShadowTheme.radiusXl),
        ),
      ),
      builder: (_) => RecordPaymentSheet(
        entityId: supplier.id,
        entityName: supplier.name,
        type: TransactionType.supplierPayment,
        outstandingBalance: supplier.outstandingBalance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = allTxns
        .where((t) => t.type == TransactionType.purchase)
        .fold<double>(0, (s, t) => s + t.totalAmount);
    final totalReturned = allTxns
        .where((t) => t.type == TransactionType.purchaseReturn)
        .fold<double>(0, (s, t) => s + t.totalAmount);

    final runningBalances = <String, double>{};
    double bal = supplier.outstandingBalance;
    for (final t in allTxns.reversed) {
      switch (t.type) {
        case TransactionType.purchase:
          bal -= (t.totalAmount - t.paidAmount);
        case TransactionType.purchaseReturn:
          bal += (t.totalAmount - t.paidAmount);
        case TransactionType.supplierPayment:
          bal += t.totalAmount;
        default:
          break;
      }
      runningBalances[t.id] = bal;
    }

    final payments = allTxns.where((t) => t.type == TransactionType.supplierPayment).toList();

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
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ShadowColors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                size: 30,
                color: ShadowColors.foreground,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    supplier.name,
                    style: ShadowTextStyles.h2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (supplier.contactPerson.isNotEmpty)
                    Text(
                      supplier.contactPerson,
                      style: ShadowTextStyles.bodyMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        RepaintBoundary(
          child: Row(
            children: [
              Expanded(
                child: ShadowStatCard(
                  label: 'Purchases',
                  value: '${allTxns.where((t) => t.type == TransactionType.purchase).length}',
                  accent: ShadowColors.accentDefault,
                ),
              ),
              const SizedBox(width: ShadowTheme.gapCard),
              Expanded(
                child: ShadowStatCard(
                  label: 'Total spent',
                  value: Formatters.currency(totalSpent),
                  accent: ShadowColors.accentTerracotta,
                ),
              ),
              const SizedBox(width: ShadowTheme.gapCard),
              Expanded(
                child: ShadowStatCard(
                  label: 'Returns',
                  value: Formatters.currency(totalReturned),
                  accent: ShadowColors.accentWarning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const ShadowSectionLabel('Contact'),
        const SizedBox(height: 12),
        ShadowCard(
          child: Column(
            children: [
              _DetailRow('Mobile', supplier.mobile.isEmpty ? '—' : supplier.mobile),
              const ShadowDivider(),
              _DetailRow('Email', supplier.email.isEmpty ? '—' : supplier.email),
              const ShadowDivider(),
              _DetailRow('Address', supplier.address.isEmpty ? '—' : supplier.address),
              const ShadowDivider(),
              _DetailRow('GST / VAT', supplier.gstVat.isEmpty ? '—' : supplier.gstVat),
              const ShadowDivider(),
              _DetailRow('Outstanding', Formatters.currency(supplier.outstandingBalance)),
            ],
          ),
        ),
        if (supplier.outstandingBalance > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadowButton(
              label: 'Make Payment — ${Formatters.currency(supplier.outstandingBalance)}',
              variant: ShadowButtonVariant.primary,
              onPressed: () => _recordPayment(context),
            ),
          ),
        ],
        if (payments.isNotEmpty) ...[
          const SizedBox(height: 24),
          const ShadowSectionLabel('Payment History'),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = payments[i];
              return ShadowCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ShadowColors.accentTerracotta.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.payments_rounded, size: 18, color: ShadowColors.accentTerracotta),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Formatters.dateTime(t.createdAt),
                            style: ShadowTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (t.notes.isNotEmpty)
                            Text(
                              t.notes,
                              style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '+${Formatters.currency(t.totalAmount)}',
                      style: ShadowTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ShadowColors.accentTerracotta,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        const ShadowSectionLabel('Transactions'),
        const SizedBox(height: 12),
        if (allTxns.isEmpty)
          ShadowCard(
            child: Text(
              'No transactions recorded for this supplier yet.',
              style: ShadowTextStyles.bodyMuted,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allTxns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = allTxns[i];
              final rb = runningBalances[t.id] ?? 0;
              final isPayment = t.type == TransactionType.supplierPayment;
              return RepaintBoundary(
                child: ShadowCard(
                  onTap: isPayment
                      ? null
                      : () => Navigator.of(context).push(
                            ShadowAnimations.fadeInUpRoute(
                              page: TransactionDetailScreen(transactionId: t.id),
                            ),
                          ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isPayment
                              ? ShadowColors.accentTerracotta.withValues(alpha: 0.15)
                              : t.type == TransactionType.purchaseReturn
                                  ? ShadowColors.accentWarning.withValues(alpha: 0.15)
                                  : ShadowColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isPayment
                              ? Icons.payments_rounded
                              : t.type == TransactionType.purchaseReturn
                                  ? Icons.assignment_return_rounded
                                  : Icons.shopping_cart_rounded,
                          size: 16,
                          color: isPayment
                              ? ShadowColors.accentTerracotta
                              : t.type == TransactionType.purchaseReturn
                                  ? ShadowColors.accentWarning
                                  : ShadowColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isPayment ? 'Payment Made' : t.type.displayLabel,
                              style: ShadowTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              Formatters.dateTime(t.createdAt),
                              style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Formatters.currency(t.totalAmount),
                            style: ShadowTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isPayment
                                  ? ShadowColors.accentTerracotta
                                  : t.type == TransactionType.purchaseReturn
                                      ? ShadowColors.accentWarning
                                      : ShadowColors.foreground,
                            ),
                          ),
                          Text(
                            'Bal: ${Formatters.currency(rb)}',
                            style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
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
