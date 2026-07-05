import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/entity_helpers.dart';
import '../../utils/export_helper.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '_invoice_pdf.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});
  final String transactionId;

  Future<void> _share(BuildContext context, Transaction t) async {
    try {
      final bytes = await InvoicePdf.build(t);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'invoice_${t.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF failed: $e')),
      );
    }
  }

  Future<void> _exportExcel(BuildContext context, Transaction t) async {
    try {
      final bytes = await ExportHelper.buildTransactionExcel(t);
      await ExportHelper.saveAndShareExcel(bytes, 'invoice_${t.id.substring(0, 8)}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel export failed: $e')),
      );
    }
  }

  Future<void> _print(BuildContext context, Transaction t) async {
    try {
      await Printing.layoutPdf(onLayout: (_) => InvoicePdf.build(t));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final t = provider.byId(transactionId);
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
                if (t != null) ...[
                  IconButton(
                    tooltip: 'Print',
                    icon: const Icon(Icons.print_outlined),
                    onPressed: () => _print(context, t),
                  ),
                  IconButton(
                    tooltip: 'Share PDF',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _share(context, t),
                  ),
                  IconButton(
                    tooltip: 'Export Excel',
                    icon: const Icon(Icons.table_chart_outlined),
                    onPressed: () => _exportExcel(context, t),
                  ),
                ],
              ],
            ),
            body: t == null
                ? const ShadowEmptyState(
                    title: 'Transaction not found',
                    icon: Icons.help_outline_rounded,
                  )
                : _Body(txn: t),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.txn});
  final Transaction txn;

  ShadowBadgeVariant get _variant {
    switch (txn.type) {
      case TransactionType.sale:
        return ShadowBadgeVariant.success;
      case TransactionType.purchase:
        return ShadowBadgeVariant.info;
      case TransactionType.salesReturn:
      case TransactionType.purchaseReturn:
        return ShadowBadgeVariant.warning;
      case TransactionType.adjustment:
        return ShadowBadgeVariant.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      cacheExtent: 500,
      padding: const EdgeInsets.fromLTRB(
        ShadowTheme.screenPaddingH,
        0,
        ShadowTheme.screenPaddingH,
        24,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadowBadge(
                      label: txn.type.displayLabel, variant: _variant),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(txn.totalAmount),
                    style: ShadowTextStyles.h1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.dateTime(txn.createdAt),
                    style: ShadowTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const ShadowSectionLabel('Summary'),
        const SizedBox(height: 12),
        ShadowCard(
          child: Column(
            children: [
              _DetailRow(
                'Entity',
                resolveEntityName(txn.entityName),
              ),
              const ShadowDivider(),
              _DetailRow('Payment', txn.paymentMethod),
              const ShadowDivider(),
              _DetailRow('Paid', Formatters.currency(txn.paidAmount)),
              const ShadowDivider(),
              _DetailRow('Balance',
                  Formatters.currency(txn.balance)),
              const ShadowDivider(),
              _DetailRow('Discount', Formatters.currency(txn.discount)),
              const ShadowDivider(),
              _DetailRow('Tax', Formatters.currency(txn.taxAmount)),
            ],
          ),
        ),
        if (txn.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          const ShadowSectionLabel('Notes'),
          const SizedBox(height: 12),
          ShadowCard(
            child: Text(txn.notes, style: ShadowTextStyles.body),
          ),
        ],
        const SizedBox(height: 20),
        const ShadowSectionLabel('Items'),
        const SizedBox(height: 12),
        if (txn.items.isEmpty)
          const ShadowCard(
            child: Text('No items on this transaction.',
                style: ShadowTextStyles.bodyMuted),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txn.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final it = txn.items[i];
              return ShadowCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Text(it.productEmoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            it.productName,
                            style: ShadowTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${it.quantity} ${it.productUnit} × ${Formatters.currency(it.priceAtTime)}',
                            style: ShadowTextStyles.bodyMuted
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.currency(it.lineSubtotal),
                      style: ShadowTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
        children: [
          Flexible(
            child: Text(label,
                style: ShadowTextStyles.bodyMuted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
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
