import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/entity_helpers.dart';
import '../../utils/export_helper.dart';
import '../../utils/formatters.dart';
import '../../widgets/record_payment_sheet.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../_shared/entity_form_sheet.dart';
import '../transactions/transaction_detail_screen.dart';

/// Balance effect of a return, mirroring the repository so statements and
/// running balances reconcile with the stored outstanding balance.
double _returnEffect(Transaction t, Map<String, Transaction> byId) =>
    returnBalanceDelta(
      t,
      t.originalTransactionId != null ? byId[t.originalTransactionId] : null,
    );

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Future<void> _confirmDelete(Customer c) async {
    final ok = await ShadowConfirmDialog.show(
      context,
      title: 'Delete customer?',
      message: '"${c.name}" will be removed.',
      danger: true,
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    final provider = context.read<CustomerProvider>();
    final navigator = Navigator.of(context);
    await provider.deleteCustomer(c.id);
    if (mounted) navigator.pop();
  }

  void _openEdit(Customer c) {
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(
        page: EntityFormSheet(kind: EntityKind.customer, customer: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CustomerProvider, TransactionProvider>(
      builder: (context, customers, txns, _) {
        final c = customers.byId(widget.customerId);
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
                if (c != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _openEdit(c),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _confirmDelete(c),
                  ),
                ],
              ],
            ),
            body: c == null
                ? const ShadowEmptyState(
                    title: 'Customer not found',
                    icon: Icons.help_outline_rounded,
                  )
                : _Body(
                    customer: c,
                    allTxns: txns.all
                        .where((t) =>
                            (t.type == TransactionType.sale ||
                             t.type == TransactionType.salesReturn ||
                             t.type == TransactionType.customerPayment) &&
                            t.entityId == c.id)
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
  const _Body({
    required this.customer,
    required this.allTxns,
  });
  final Customer customer;
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
        entityId: customer.id,
        entityName: customer.name,
        type: TransactionType.customerPayment,
        outstandingBalance: customer.outstandingBalance,
      ),
    );
  }

  Future<void> _downloadStatement(BuildContext context) async {
    final asc = List<Transaction>.from(allTxns)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final txnById = {for (final t in allTxns) t.id: t};
    double delta = 0;
    for (final t in allTxns) {
      switch (t.type) {
        case TransactionType.sale:
          delta += (t.totalAmount - t.paidAmount);
        case TransactionType.salesReturn:
          delta -= _returnEffect(t, txnById);
        case TransactionType.customerPayment:
          delta -= t.totalAmount;
        default:
          break;
      }
    }
    final opening = customer.outstandingBalance - delta;
    var run = opening;
    final rows = <StatementRow>[];
    for (final t in asc) {
      final amt = switch (t.type) {
        TransactionType.sale => (t.totalAmount - t.paidAmount),
        TransactionType.salesReturn => _returnEffect(t, txnById),
        TransactionType.customerPayment => -t.totalAmount,
        _ => 0.0,
      };
      switch (t.type) {
        case TransactionType.sale:
          run += (t.totalAmount - t.paidAmount);
        case TransactionType.salesReturn:
          run += _returnEffect(t, txnById);
        case TransactionType.customerPayment:
          run -= t.totalAmount;
        default:
          break;
      }
      rows.add(ExportHelper.statementRow(
        date: t.createdAt,
        description: t.type.displayLabel,
        type: t.type.displayLabel,
        amount: amt,
        balance: run,
      ));
    }
    final pdf = await ExportHelper.buildStatementPdf(
      entityName: customer.name,
      entityType: 'Customer',
      openingBalance: opening,
      closingBalance: customer.outstandingBalance,
      rows: rows,
    );
    await ExportHelper.sharePdf(pdf, 'statement_${customer.name}');
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = allTxns
        .where((t) => t.type == TransactionType.sale)
        .fold<double>(0, (s, t) => s + (t.totalAmount - t.taxAmount));
    final totalReturned = allTxns
        .where((t) => t.type == TransactionType.salesReturn)
        .fold<double>(0, (s, t) => s + (t.totalAmount - t.taxAmount));

    // Lookup for original transactions so returns use the same balance effect
    // as the repository (capped at the original's outstanding amount).
    final txnById = {for (final t in allTxns) t.id: t};

    // Running balance: start at current outstanding and walk backwards
    // through transactions to compute intermediate balances
    final runningBalances = <String, double>{};
    double bal = customer.outstandingBalance;
    for (final t in allTxns) {
      switch (t.type) {
        case TransactionType.sale:
          bal -= (t.totalAmount - t.paidAmount);
        case TransactionType.salesReturn:
          bal -= _returnEffect(t, txnById);
        case TransactionType.customerPayment:
          bal += t.totalAmount;
        default:
          break;
      }
      runningBalances[t.id] = bal;
    }

    final payments = allTxns.where((t) => t.type == TransactionType.customerPayment).toList();

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
              child: Text(
                customer.name.isEmpty
                    ? '?'
                    : customer.name.substring(0, 1).toUpperCase(),
                style: ShadowTextStyles.h2,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customer.name,
                    style: ShadowTextStyles.h2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customer.mobile.isNotEmpty)
                    Text(
                      customer.mobile,
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
                  label: 'Sales',
                  value: '${allTxns.where((t) => t.type == TransactionType.sale).length}',
                  accent: ShadowColors.accentDefault,
                ),
              ),
              const SizedBox(width: ShadowTheme.gapCard),
              Expanded(
                child: ShadowStatCard(
                  label: 'Revenue',
                  value: Formatters.currency(totalRevenue),
                  accent: ShadowColors.accentSage,
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
              _DetailRow('Mobile', customer.mobile.isEmpty ? '—' : customer.mobile),
              const ShadowDivider(),
              _DetailRow('Email', customer.email.isEmpty ? '—' : customer.email),
              const ShadowDivider(),
              _DetailRow('Address', customer.address.isEmpty ? '—' : customer.address),
              const ShadowDivider(),
              _DetailRow('GST / VAT', customer.gstVat.isEmpty ? '—' : customer.gstVat),
              const ShadowDivider(),
              _DetailRow('Outstanding', Formatters.currency(customer.outstandingBalance)),
            ],
          ),
        ),
        if (customer.outstandingBalance > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadowButton(
              label: 'Collect Payment — ${Formatters.currency(customer.outstandingBalance)}',
              variant: ShadowButtonVariant.primary,
              onPressed: () => _recordPayment(context),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ShadowButton(
            label: 'Download Statement (PDF)',
            variant: ShadowButtonVariant.secondary,
            icon: Icons.picture_as_pdf_rounded,
            onPressed: () => _downloadStatement(context),
          ),
        ),
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
                        color: ShadowColors.accentSage.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.payments_rounded, size: 18, color: ShadowColors.accentSage),
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
                        color: ShadowColors.accentSage,
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
              'No transactions recorded for this customer yet.',
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
              final isPayment = t.type == TransactionType.customerPayment;
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
                              ? ShadowColors.accentSage.withValues(alpha: 0.15)
                              : t.type == TransactionType.salesReturn
                                  ? ShadowColors.accentWarning.withValues(alpha: 0.15)
                                  : ShadowColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isPayment
                              ? Icons.payments_rounded
                              : t.type == TransactionType.salesReturn
                                  ? Icons.assignment_return_rounded
                                  : Icons.shopping_bag_rounded,
                          size: 16,
                          color: isPayment
                              ? ShadowColors.accentSage
                              : t.type == TransactionType.salesReturn
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
                              isPayment ? 'Payment Received' : t.type.displayLabel,
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
                            isPayment
                                ? Formatters.currency(t.totalAmount)
                                : Formatters.currency(t.totalAmount),
                            style: ShadowTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isPayment
                                  ? ShadowColors.accentSage
                                  : t.type == TransactionType.salesReturn
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
