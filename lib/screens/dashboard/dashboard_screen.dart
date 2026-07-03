import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/transaction.dart';
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

/// The main landing tab. Reads from all four providers and lays out
/// header → alert banners → stats → quick metrics → recent products →
/// recent transactions. No business logic here — every number comes
/// from a provider getter.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<ProductProvider, CustomerProvider, SupplierProvider,
        TransactionProvider>(
      builder: (context, products, customers, suppliers, txns, _) {
        final anyLoading = products.isLoading ||
            customers.isLoading ||
            suppliers.isLoading ||
            txns.isLoading;
        final firstError = products.error ??
            customers.error ??
            suppliers.error ??
            txns.error;

        if (anyLoading && products.all.isEmpty) {
          return const _DashboardLoading();
        }
        if (firstError != null && products.all.isEmpty) {
          return _DashboardError(
            error: firstError,
            onRetry: () {
              products.load();
              customers.load();
              suppliers.load();
              txns.load();
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              products.load(),
              customers.load(),
              suppliers.load(),
              txns.load(),
            ]);
          },
          color: ShadowColors.primary,
          backgroundColor: ShadowColors.card,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const ShadowPageHeader(
                title: 'Dashboard',
                subtitle: 'Real-time inventory insights',
              ),
              _AlertBanners(
                outOfStock: products.outOfStockCount,
                lowStock: products.lowStockCount,
              ),
              const SizedBox(height: 8),
              _StatsRow(
                totalProducts: products.totalProducts,
                totalStock: products.totalStock,
                inventoryValue: products.inventoryValue,
                todaysRevenue: txns.revenueForDay(DateTime.now()),
              ),
              const SizedBox(height: ShadowTheme.gapSection),
              _QuickMetricsGrid(
                outOfStock: products.outOfStockCount,
                lowStock: products.lowStockCount,
                customers: customers.totalCustomers,
                suppliers: suppliers.totalSuppliers,
              ),
              const SizedBox(height: ShadowTheme.gapSection),
              _RecentProducts(products: products.recent()),
              const SizedBox(height: ShadowTheme.gapSection),
              _RecentTransactions(transactions: txns.recent()),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ─── Alert banners ───────────────────────────────────────────────────

class _AlertBanners extends StatelessWidget {
  const _AlertBanners({required this.outOfStock, required this.lowStock});
  final int outOfStock;
  final int lowStock;

  @override
  Widget build(BuildContext context) {
    if (outOfStock == 0 && lowStock == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
      ),
      child: Column(
        children: [
          if (outOfStock > 0)
            _AlertBanner(
              icon: Icons.error_outline_rounded,
              accent: ShadowColors.destructive,
              title: '$outOfStock ${outOfStock == 1 ? 'product' : 'products'} out of stock',
              subtitle: 'Restock soon to avoid missed sales.',
            ),
          if (outOfStock > 0 && lowStock > 0) const SizedBox(height: 10),
          if (lowStock > 0)
            _AlertBanner(
              icon: Icons.warning_amber_rounded,
              accent: ShadowColors.accentWarning,
              title: '$lowStock low stock ${lowStock == 1 ? 'item' : 'items'}',
              subtitle: 'Below alert threshold — plan reorders.',
            ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      leftAccent: accent,
      backgroundColor: Color.alphaBlend(
        accent.withValues(alpha: 0.08),
        ShadowColors.card,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: ShadowTextStyles.bodyMuted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row (4 ShadowStatCard) ────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalProducts,
    required this.totalStock,
    required this.inventoryValue,
    required this.todaysRevenue,
  });

  final int totalProducts;
  final int totalStock;
  final double inventoryValue;
  final double todaysRevenue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: ShadowTheme.screenPaddingH,
        ),
        children: [
          _statCell(
            label: 'Total Products',
            value: '$totalProducts',
            sub: 'in catalog',
            accent: ShadowColors.accentDefault,
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(width: ShadowTheme.gapCard),
          _statCell(
            label: 'Total Stock',
            value: Formatters.compact(totalStock),
            sub: 'units on hand',
            accent: ShadowColors.accentSage,
            icon: Icons.warehouse_outlined,
          ),
          const SizedBox(width: ShadowTheme.gapCard),
          _statCell(
            label: 'Inventory Value',
            value: Formatters.currency(inventoryValue),
            sub: 'at cost',
            accent: ShadowColors.accentOlive,
            icon: Icons.savings_outlined,
          ),
          const SizedBox(width: ShadowTheme.gapCard),
          _statCell(
            label: "Today's Revenue",
            value: Formatters.currency(todaysRevenue),
            sub: 'gross sales',
            accent: ShadowColors.accentTerracotta,
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }

  Widget _statCell({
    required String label,
    required String value,
    required String sub,
    required Color accent,
    required IconData icon,
  }) {
    return SizedBox(
      width: 200,
      child: ShadowStatCard(
        label: label,
        value: value,
        sub: sub,
        accent: accent,
        icon: icon,
      ),
    );
  }
}

// ─── Quick metrics 2×2 grid ─────────────────────────────────────────

class _QuickMetricsGrid extends StatelessWidget {
  const _QuickMetricsGrid({
    required this.outOfStock,
    required this.lowStock,
    required this.customers,
    required this.suppliers,
  });

  final int outOfStock;
  final int lowStock;
  final int customers;
  final int suppliers;

  @override
  Widget build(BuildContext context) {
    final cells = [
      _MetricCell(
        label: 'Out of Stock',
        value: '$outOfStock',
        icon: Icons.remove_shopping_cart_outlined,
        accent: ShadowColors.destructive,
      ),
      _MetricCell(
        label: 'Low Stock',
        value: '$lowStock',
        icon: Icons.warning_amber_rounded,
        accent: ShadowColors.accentWarning,
      ),
      _MetricCell(
        label: 'Customers',
        value: '$customers',
        icon: Icons.people_alt_outlined,
        accent: ShadowColors.accent,
      ),
      _MetricCell(
        label: 'Suppliers',
        value: '$suppliers',
        icon: Icons.local_shipping_outlined,
        accent: ShadowColors.accentSage,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShadowSectionLabel('Quick metrics'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cells[0]),
              const SizedBox(width: ShadowTheme.gapCard),
              Expanded(child: cells[1]),
            ],
          ),
          const SizedBox(height: ShadowTheme.gapCard),
          Row(
            children: [
              Expanded(child: cells[2]),
              const SizedBox(width: ShadowTheme.gapCard),
              Expanded(child: cells[3]),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.15),
                ShadowColors.card,
              ),
              borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: ShadowTextStyles.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent products (horizontal strip) ─────────────────────────────

class _RecentProducts extends StatelessWidget {
  const _RecentProducts({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ShadowTheme.screenPaddingH,
          ),
          child: const ShadowSectionLabel('Recent products'),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ShadowTheme.screenPaddingH,
            ),
            child: ShadowCard(
              child: Text(
                'No products yet. Add one to get started.',
                style: ShadowTextStyles.bodyMuted,
              ),
            ),
          )
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: ShadowTheme.screenPaddingH,
              ),
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: ShadowTheme.gapCard),
              itemBuilder: (context, i) =>
                  _RecentProductCard(product: products[i]),
            ),
          ),
      ],
    );
  }
}

class _RecentProductCard extends StatelessWidget {
  const _RecentProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final variant = product.isOutOfStock
        ? ShadowBadgeVariant.danger
        : product.isLowStock
            ? ShadowBadgeVariant.warning
            : ShadowBadgeVariant.success;
    final stockLabel = product.isOutOfStock
        ? 'Out'
        : '${product.stock} ${product.unit}';
    return SizedBox(
      width: 172,
      child: ShadowCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(product.emoji, style: const TextStyle(fontSize: 24)),
                const Spacer(),
                ShadowBadge(label: stockLabel, variant: variant),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: ShadowTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.currency(product.sellPrice),
              style: ShadowTextStyles.bodyMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent transactions (vertical list) ────────────────────────────

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShadowSectionLabel('Recent transactions'),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            ShadowCard(
              child: Text(
                'No transactions yet.',
                style: ShadowTextStyles.bodyMuted,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: ShadowTheme.gapCard),
              itemBuilder: (context, i) =>
                  _TxnRow(txn: transactions[i]),
            ),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});
  final Transaction txn;

  ShadowBadgeVariant get _variant {
    switch (txn.type) {
      case TransactionType.sale:
        return ShadowBadgeVariant.success;
      case TransactionType.purchase:
        return ShadowBadgeVariant.info;
      case TransactionType.salesReturn:
        return ShadowBadgeVariant.warning;
      case TransactionType.purchaseReturn:
        return ShadowBadgeVariant.warning;
      case TransactionType.adjustment:
        return ShadowBadgeVariant.muted;
    }
  }

  bool get _isOutbound =>
      txn.type == TransactionType.purchase ||
      txn.type == TransactionType.salesReturn;

  @override
  Widget build(BuildContext context) {
    final entity = txn.entityName.isEmpty ? '—' : txn.entityName;
    final sign = _isOutbound ? '-' : '+';
    return ShadowCard(
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
                      label: txn.type.displayLabel,
                      variant: _variant,
                    ),
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
                  Formatters.relative(txn.createdAt),
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$sign${Formatters.currency(txn.totalAmount)}',
            style: ShadowTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: _isOutbound
                  ? ShadowColors.destructive
                  : ShadowColors.accentSage,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Loading + error placeholders ───────────────────────────────────

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        ShadowPageHeader(
          title: 'Dashboard',
          subtitle: 'Real-time inventory insights',
        ),
        SizedBox(height: 8),
        _SkeletonRow(),
        SizedBox(height: 24),
        _SkeletonRow(),
        SizedBox(height: 24),
        SkeletonList.card(count: 3),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
      ),
      child: Row(
        children: const [
          Expanded(child: ShadowSkeleton(height: 96)),
          SizedBox(width: ShadowTheme.gapCard),
          Expanded(child: ShadowSkeleton(height: 96)),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ShadowPageHeader(
          title: 'Dashboard',
          subtitle: 'Real-time inventory insights',
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: ShadowEmptyState(
            title: "Couldn't load dashboard",
            subtitle: error.toString(),
            icon: Icons.error_outline_rounded,
            iconColor: ShadowColors.destructive,
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
        ),
      ],
    );
  }
}

