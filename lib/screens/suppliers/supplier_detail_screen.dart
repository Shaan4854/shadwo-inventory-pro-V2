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

class SupplierDetailScreen extends StatelessWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});
  final String supplierId;

  Future<void> _confirmDelete(BuildContext context, Supplier s) async {
    final ok = await ShadowConfirmDialog.show(
      context,
      title: 'Delete supplier?',
      message: '"${s.name}" will be removed.',
      danger: true,
      confirmLabel: 'Delete',
    );
    if (!ok || !context.mounted) return;
    await context.read<SupplierProvider>().deleteSupplier(s.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _openEdit(BuildContext context, Supplier s) {
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
        final s = suppliers.byId(supplierId);
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
                    onPressed: () => _openEdit(context, s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _confirmDelete(context, s),
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
                  ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.supplier, required this.purchases});
  final Supplier supplier;
  final List<Transaction> purchases;

  @override
  Widget build(BuildContext context) {
    final totalSpent =
        purchases.fold<double>(0, (s, t) => s + t.totalAmount);
    return ListView(
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
        Row(
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
        const SizedBox(height: 24),
        const ShadowSectionLabel('Contact'),
        const SizedBox(height: 12),
        ShadowCard(
          child: Column(
            children: [
              _DetailRow('Mobile',
                  supplier.mobile.isEmpty ? '—' : supplier.mobile),
              const ShadowDivider(),
              _DetailRow('Email',
                  supplier.email.isEmpty ? '—' : supplier.email),
              const ShadowDivider(),
              _DetailRow('Address',
                  supplier.address.isEmpty ? '—' : supplier.address),
              const ShadowDivider(),
              _DetailRow('GST / VAT',
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
          ShadowCard(
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
              return ShadowCard(
                onTap: () {
                  Navigator.of(context).push(
                    ShadowAnimations.fadeInUpRoute(
                      page: TransactionDetailScreen(transactionId: t.id),
                    ),
                  );
                },
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          Expanded(
            child: Text(label, style: ShadowTextStyles.bodyMuted,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: ShadowTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
