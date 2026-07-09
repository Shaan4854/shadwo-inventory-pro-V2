import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_type.dart';
import '../../providers/customer_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/record_payment_sheet.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../customers/customer_detail_screen.dart';
import '../suppliers/supplier_detail_screen.dart';

class DueCollectionScreen extends StatefulWidget {
  const DueCollectionScreen({super.key});

  @override
  State<DueCollectionScreen> createState() => _DueCollectionScreenState();
}

class _DueCollectionScreenState extends State<DueCollectionScreen> {
  int _selectedTab = 0;

  void _recordPayment({
    required String entityId,
    required String entityName,
    required TransactionType type,
    required double outstandingBalance,
  }) {
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
        entityId: entityId,
        entityName: entityName,
        type: type,
        outstandingBalance: outstandingBalance,
      ),
    );
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
          title: Text(
            'Due Collection',
            style: ShadowTextStyles.h4,
          ),
        ),
        body: Consumer2<CustomerProvider, SupplierProvider>(
          builder: (context, customers, suppliers, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ShadowTheme.screenPaddingH),
                  child: Row(
                    children: [
                      _TabChip(
                        label: 'Customers',
                        count: customers.all
                            .where((c) => c.outstandingBalance > 0)
                            .length,
                        active: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 10),
                      _TabChip(
                        label: 'Suppliers',
                        count: suppliers.all
                            .where((s) => s.outstandingBalance > 0)
                            .length,
                        active: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedTab == 0
                      ? _CustomerDuesList(
                          onRecordPayment: (id, name, balance) =>
                              _recordPayment(
                            entityId: id,
                            entityName: name,
                            type: TransactionType.customerPayment,
                            outstandingBalance: balance,
                          ),
                        )
                      : _SupplierDuesList(
                          onRecordPayment: (id, name, balance) =>
                              _recordPayment(
                            entityId: id,
                            entityName: name,
                            type: TransactionType.supplierPayment,
                            outstandingBalance: balance,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? ShadowColors.primary.withValues(alpha: 0.12)
              : ShadowColors.muted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(color: ShadowColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: ShadowTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: active ? ShadowColors.primary : ShadowColors.mutedForeground,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? ShadowColors.primary : ShadowColors.mutedForeground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerDuesList extends StatelessWidget {
  const _CustomerDuesList({required this.onRecordPayment});

  final void Function(String id, String name, double balance) onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>();
    final dueCustomers =
        customers.all.where((c) => c.outstandingBalance > 0).toList()
          ..sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));

    if (dueCustomers.isEmpty) {
      return const ShadowEmptyState(
        title: 'No dues',
        subtitle: 'All customers have cleared their balances.',
        icon: Icons.check_circle_outline_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: ShadowTheme.screenPaddingH),
      physics: const BouncingScrollPhysics(),
      itemCount: dueCustomers.length,
      itemBuilder: (context, i) {
        final c = dueCustomers[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShadowCard(
            onTap: () => Navigator.of(context).push(
              ShadowAnimations.fadeInUpRoute(
                page: CustomerDetailScreen(customerId: c.id),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ShadowColors.destructive.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    c.name.isNotEmpty
                        ? c.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: ShadowTextStyles.h3.copyWith(
                      color: ShadowColors.destructive,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.name,
                        style: ShadowTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (c.mobile.isNotEmpty)
                        Text(
                          c.mobile,
                          style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.currency(c.outstandingBalance),
                      style: ShadowTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ShadowColors.destructive,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 30,
                      child: ShadowButton(
                        label: 'Collect',
                        variant: ShadowButtonVariant.primary,
                        size: ShadowButtonSize.sm,
                        onPressed: () => onRecordPayment(
                          c.id,
                          c.name,
                          c.outstandingBalance,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupplierDuesList extends StatelessWidget {
  const _SupplierDuesList({required this.onRecordPayment});

  final void Function(String id, String name, double balance) onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>();
    final dueSuppliers =
        suppliers.all.where((s) => s.outstandingBalance > 0).toList()
          ..sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));

    if (dueSuppliers.isEmpty) {
      return const ShadowEmptyState(
        title: 'No dues',
        subtitle: 'All supplier balances are cleared.',
        icon: Icons.check_circle_outline_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: ShadowTheme.screenPaddingH),
      physics: const BouncingScrollPhysics(),
      itemCount: dueSuppliers.length,
      itemBuilder: (context, i) {
        final s = dueSuppliers[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShadowCard(
            onTap: () => Navigator.of(context).push(
              ShadowAnimations.fadeInUpRoute(
                page: SupplierDetailScreen(supplierId: s.id),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ShadowColors.destructive.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.name,
                        style: ShadowTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (s.mobile.isNotEmpty)
                        Text(
                          s.mobile,
                          style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.currency(s.outstandingBalance),
                      style: ShadowTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ShadowColors.destructive,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 30,
                      child: ShadowButton(
                        label: 'Pay',
                        variant: ShadowButtonVariant.primary,
                        size: ShadowButtonSize.sm,
                        onPressed: () => onRecordPayment(
                          s.id,
                          s.name,
                          s.outstandingBalance,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
