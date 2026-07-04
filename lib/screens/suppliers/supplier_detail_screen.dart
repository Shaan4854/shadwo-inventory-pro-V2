import 'package:flutter/material.dart';
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
              const BoxDecoration(gradient: ShadowColors.pageBackground),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme:
                  const IconThemeData(color: ShadowColors.foreground),
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
                    purchases: txns.all
                        .where((t) =>
                            t.type == TransactionType.purchase &&
                            t.entityId == s.id)
                        .toList(),
                    returns: txns.all
                        .where((t) =>
                            t.type == TransactionType.purchaseReturn &&
                            t.entityId == s.id)
                        .toList(),
                  ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.supplier, required this.purchases, required this.returns});
  final Supplier supplier;
  final List<Transaction> purchases;
  final List<Transaction> returns;

  @override
  Widget build(BuildContext context) {
    final totalSpent =
        purchases.fold<double>(0, (s, t) => s + t.totalAmount);
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
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: ShadowColors.muted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
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
                  label: 'Total purchases',
                  value: '${purchases.length}',
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
                  supplier.mobile.isEmpty ? '—' : supplier.mobile),
              const ShadowDivider(),
              _DetailRow(
                  'Email',
                  supplier.email.isEmpty ? '—' : supplier.email),
              const ShadowDivider(),
              _DetailRow(
                  'Address',
                  supplier.address.isEmpty ? '—' : supplier.address),
              const ShadowDivider(),
              _DetailRow(
                  'GST / VAT',
                  supplier.gstVat.isEmpty ? '—' : supplier.gstVat),
              const ShadowDivider(),
              _DetailRow(
                'Outstanding',
                Formatters.currency(supplier.outstandingBalance),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const ShadowSectionLabel('Recent purchases'),
        const SizedBox(height: 12),
        if (purchases.isEmpty)
          const ShadowCard(
            child: Text(
              'No purchases recorded from this supplier yet.',
              style: ShadowTextStyles.bodyMuted,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: purchases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = purchases[i];
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
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (returns.isNotEmpty) ...[
          const SizedBox(height: 24),
          const ShadowSectionLabel('Purchase returns'),
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
        children: [
          Flexible(
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
              style: ShadowTextStyles.body.copyWith(fontWeight: FontWeight.w600),
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
