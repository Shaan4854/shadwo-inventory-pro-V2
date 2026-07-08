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
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../_shared/entity_form_sheet.dart';
import '../transactions/transaction_detail_screen.dart';

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
                    sales: txns.all
                        .where((t) =>
                            t.type == TransactionType.sale &&
                            t.entityId == c.id)
                        .toList(),
                    returns: txns.all
                        .where((t) =>
                            t.type == TransactionType.salesReturn &&
                            t.entityId == c.id)
                        .toList(),
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
    required this.sales,
    required this.returns,
  });
  final Customer customer;
  final List<Transaction> sales;
  final List<Transaction> returns;

  @override
  Widget build(BuildContext context) {
    final totalRevenue =
        sales.fold<double>(0, (s, t) => s + t.totalAmount);
    final totalReturned =
        returns.fold<double>(0, (s, t) => s + t.totalAmount);
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
                  label: 'Total Sales',
                  value: '${sales.length}',
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
              _DetailRow(
                  'Mobile',
                  customer.mobile.isEmpty ? '—' : customer.mobile),
              const ShadowDivider(),
              _DetailRow(
                  'Email',
                  customer.email.isEmpty ? '—' : customer.email),
              const ShadowDivider(),
              _DetailRow(
                  'Address',
                  customer.address.isEmpty ? '—' : customer.address),
              const ShadowDivider(),
              _DetailRow(
                  'GST / VAT',
                  customer.gstVat.isEmpty ? '—' : customer.gstVat),
              const ShadowDivider(),
              _DetailRow(
                'Outstanding',
                Formatters.currency(customer.outstandingBalance),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const ShadowSectionLabel('Recent sales'),
        const SizedBox(height: 12),
        if (sales.isEmpty)
          ShadowCard(
            child: Text(
              'No sales recorded for this customer yet.',
              style: ShadowTextStyles.bodyMuted,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = sales[i];
              return RepaintBoundary(
                child: ShadowCard(
                  onTap: () => Navigator.of(context).push(
                    ShadowAnimations.fadeInUpRoute(
                      page: TransactionDetailScreen(transactionId: t.id),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.dateTime(t.createdAt),
                              style: ShadowTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${t.items.length} item${t.items.length == 1 ? '' : 's'}',
                              style: ShadowTextStyles.bodyMuted
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(t.totalAmount),
                        style: ShadowTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ShadowColors.accentSage,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (returns.isNotEmpty) ...[
          const SizedBox(height: 24),
          const ShadowSectionLabel('Sales returns'),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: returns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = returns[i];
              return RepaintBoundary(
                child: ShadowCard(
                  onTap: () => Navigator.of(context).push(
                    ShadowAnimations.fadeInUpRoute(
                      page: TransactionDetailScreen(transactionId: t.id),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.dateTime(t.createdAt),
                              style: ShadowTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${t.items.length} item${t.items.length == 1 ? '' : 's'}',
                              style: ShadowTextStyles.bodyMuted
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(t.totalAmount),
                        style: ShadowTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ShadowColors.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
