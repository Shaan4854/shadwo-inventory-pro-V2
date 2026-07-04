import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/entity_helpers.dart';
import '../../utils/export_helper.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _typeFilter;
  bool _firstBuild = true;

  Iterable<Transaction> _filter(List<Transaction> all) {
    if (_typeFilter == null) return all;
    return all.where((t) => t.type == _typeFilter);
  }

  Future<void> _export(BuildContext context, String format,
      List<Transaction> txns) async {
    if (txns.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }
    try {
      if (format == 'pdf') {
        final bytes = await ExportHelper.buildTransactionsPdf(txns);
        await ExportHelper.sharePdf(bytes, 'transactions');
      } else {
        final bytes = await ExportHelper.buildTransactionsExcel(txns);
        await ExportHelper.saveAndShareExcel(
            bytes, 'transactions_export');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _firstBuild;
    if (_firstBuild) _firstBuild = false;
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final list = _filter(provider.all).toList(growable: false);
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.file_download_outlined),
                  color: ShadowColors.card,
                  onSelected: (v) => _export(context, v, list),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
                    PopupMenuItem(value: 'xlsx', child: Text('Export as Excel')),
                  ],
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: provider.load,
              color: ShadowColors.primary,
              backgroundColor: ShadowColors.card,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                cacheExtent: 500,
                slivers: [
                  const SliverToBoxAdapter(
                    child: ShadowPageHeader(
                      title: 'Transactions',
                      subtitle: 'All ledger entries',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        cacheExtent: 500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: ShadowTheme.screenPaddingH,
                        ),
                        itemCount: TransactionType.values.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return ShadowFilterChip(
                              label: 'All',
                              selected: _typeFilter == null,
                              onTap: () =>
                                  setState(() => _typeFilter = null),
                            );
                          }
                          final t = TransactionType.values[i - 1];
                          return ShadowFilterChip(
                            label: t.displayLabel,
                            selected: _typeFilter == t,
                            onTap: () =>
                                setState(() => _typeFilter = t),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (provider.isLoading && provider.all.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: SkeletonList.card(count: 5),
                    )
                  else if (provider.error != null && provider.all.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ShadowEmptyState(
                        title: "Couldn't load transactions",
                        subtitle: provider.error.toString(),
                        icon: Icons.error_outline_rounded,
                        iconColor: ShadowColors.destructive,
                        actionLabel: 'Retry',
                        onAction: provider.load,
                      ),
                    )
                  else if (list.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ShadowEmptyState(
                        title: 'No transactions',
                        subtitle:
                            'Complete a sale or purchase to see it here.',
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        ShadowTheme.screenPaddingH,
                        0,
                        ShadowTheme.screenPaddingH,
                        24,
                      ),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final t = list[i];
                          final row = RepaintBoundary(
                            child: _TxnRow(
                              txn: t,
                              onTap: () {
                                Navigator.of(context).push(
                                  ShadowAnimations.fadeInUpRoute(
                                    page: TransactionDetailScreen(
                                      transactionId: t.id,
                                    ),
                                  ),
                                );
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
            ),
          ),
        );
      },
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn, required this.onTap});
  final Transaction txn;
  final VoidCallback onTap;

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

  bool get _outbound =>
      txn.type == TransactionType.purchase ||
      txn.type == TransactionType.salesReturn;

  @override
  Widget build(BuildContext context) {
    final entity = resolveEntityName(txn.entityName);
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ShadowBadge(
                        label: txn.type.displayLabel, variant: _variant),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        entity,
                        style: ShadowTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.dateTime(txn.createdAt)} · ${txn.items.length} item${txn.items.length == 1 ? '' : 's'} · ${txn.paymentMethod}',
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_outbound ? '-' : '+'}${Formatters.currency(txn.totalAmount)}',
                style: ShadowTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _outbound
                      ? ShadowColors.destructive
                      : ShadowColors.accentSage,
                ),
              ),
              if (txn.balance > 0)
                Text(
                  'Due ${Formatters.currency(txn.balance)}',
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
