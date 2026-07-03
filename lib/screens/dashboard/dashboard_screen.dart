import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/report_filter.dart';
import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/page_header.dart';
import '../../widgets/ui_kit/shadow_badge.dart';
import '../../widgets/ui_kit/shadow_button.dart';
import '../../widgets/ui_kit/shadow_empty_state.dart';
import '../../widgets/ui_kit/shadow_section_label.dart';
import '../../widgets/ui_kit/shadow_skeleton.dart';
import '../../widgets/ui_kit/stat_card.dart';

/// Home tab — 4 top-level stats, alert banners, quick metrics, and
/// recent activity. Reads only already-computed provider data; no
/// aggregation happens in this file beyond bounded `.take(N)` slicing
/// for the "recent" lists.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _appliedTodayFilter = false;

  @override
  void initState() {
    super.initState();
    // ReportsProvider's default filter is a rolling 30-day window (its
    // own constructor default) — Dashboard needs "today" specifically
    // for the revenue stat, so we set it once after the first frame.
    //
    // NOTE for whoever builds Step 11 (Reports screen): ReportsProvider
    // is a single shared instance. If Reports doesn't set its own
    // filter on init, it will inherit this "today" filter left behind
    // by Dashboard instead of its own intended default.
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyTodayFilterOnce());
  }

  void _applyTodayFilterOnce() {
    if (_appliedTodayFilter || !mounted) return;
    _appliedTodayFilter = true;
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    context.read<ReportsProvider>().updateFilter(
          ReportFilter(startDate: todayStart, endDate: todayStart),
        );
  }

  @override
  Widget build(BuildContext context) {
    final ProductProvider productProvider = context.watch<ProductProvider>();

    if (productProvider.isLoading && productProvider.totalItems == 0) {
      return const _DashboardLoading();
    }

    if (productProvider.errorMessage != null) {
      return _DashboardError(
        message: productProvider.errorMessage!,
        onRetry: () => productProvider.loadProducts(),
      );
    }

    return const _DashboardContent();
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ShadowColors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ShadowSkeleton(count: 1, height: 64),
              SizedBox(height: 24),
              ShadowSkeleton(count: 4, height: 110),
              SizedBox(height: 24),
              ShadowSkeleton(count: 3, height: 72),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShadowColors.background,
      child: SafeArea(
        child: Center(
          child: ShadowEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            description: message,
            action: ShadowButton(label: 'Retry', onPressed: onRetry),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final ProductProvider productProvider = context.watch<ProductProvider>();
    final CustomerProvider customerProvider = context.watch<CustomerProvider>();
    final SupplierProvider supplierProvider = context.watch<SupplierProvider>();
    final ReportsProvider reportsProvider = context.watch<ReportsProvider>();

    final int outOfStock = productProvider.outOfStockCount;
    final int lowStock = productProvider.lowStockCount;
    final List<Product> recentProducts = productProvider.products.take(6).toList();
    final List<Transaction> recentTransactions =
        productProvider.transactions.take(5).toList();

    return ColoredBox(
      color: ShadowColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const ShadowPageHeader(
                title: 'Dashboard',
                subtitle: 'Real-time inventory insights',
              ),
              if (outOfStock > 0)
                _AlertBanner(
                  color: ShadowColors.destructive,
                  message: '$outOfStock product${outOfStock == 1 ? '' : 's'} out of stock',
                ),
              if (outOfStock > 0 && lowStock > 0) const SizedBox(height: 12),
              if (lowStock > 0)
                _AlertBanner(
                  color: ShadowColors.accentWarning,
                  message: '$lowStock product${lowStock == 1 ? '' : 's'} running low',
                ),
              if (outOfStock > 0 || lowStock > 0) const SizedBox(height: 24),
              _StatsRow(
                totalProducts: productProvider.totalItems,
                totalStock: productProvider.totalStock,
                inventoryValue: productProvider.totalSellValue,
                todayRevenue: reportsProvider.totalRevenue,
              ),
              const SizedBox(height: 20),
              _QuickMetricsGrid(
                outOfStock: outOfStock,
                lowStock: lowStock,
                customers: customerProvider.customers.length,
                suppliers: supplierProvider.suppliers.length,
              ),
              const SizedBox(height: 24),
              const ShadowSectionLabel('Recent Products'),
              _RecentProducts(products: recentProducts),
              const SizedBox(height: 24),
              const ShadowSectionLabel('Recent Transactions'),
              _RecentTransactions(transactions: recentTransactions),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.color, required this.message});

  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalProducts,
    required this.totalStock,
    required this.inventoryValue,
    required this.todayRevenue,
  });

  final int totalProducts;
  final int totalStock;
  final double inventoryValue;
  final double todayRevenue;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: <Widget>[
        ShadowStatCard(
          label: 'Total Products',
          value: '$totalProducts',
          accent: ShadowStatAccent.defaultAccent,
        ),
        ShadowStatCard(
          label: 'Total Stock',
          value: Formatters.compact(totalStock),
          accent: ShadowStatAccent.sage,
        ),
        ShadowStatCard(
          label: 'Inventory Value',
          value: Formatters.currency(inventoryValue),
          accent: ShadowStatAccent.olive,
        ),
        ShadowStatCard(
          label: "Today's Revenue",
          value: Formatters.currency(todayRevenue),
          accent: ShadowStatAccent.terracotta,
        ),
      ],
    );
  }
}

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
    final List<_QuickMetric> metrics = <_QuickMetric>[
      _QuickMetric(label: 'Out of Stock', value: outOfStock, icon: Icons.remove_shopping_cart_rounded),
      _QuickMetric(label: 'Low Stock', value: lowStock, icon: Icons.warning_amber_rounded),
      _QuickMetric(label: 'Customers', value: customers, icon: Icons.people_alt_rounded),
      _QuickMetric(label: 'Suppliers', value: suppliers, icon: Icons.local_shipping_rounded),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: <Widget>[for (final _QuickMetric metric in metrics) _QuickMetricTile(metric: metric)],
    );
  }
}

class _QuickMetric {
  const _QuickMetric({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;
}

class _QuickMetricTile extends StatelessWidget {
  const _QuickMetricTile({required this.metric});

  final _QuickMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ShadowColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShadowColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          Icon(metric.icon, size: 20, color: ShadowColors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('${metric.value}', style: ShadowTextStyles.h4),
                Text(
                  metric.label,
                  style: const TextStyle(fontSize: 11, color: ShadowColors.mutedForeground),
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

class _RecentProducts extends StatelessWidget {
  const _RecentProducts({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const ShadowEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        description: 'Products you add will show up here.',
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (BuildContext context, int index) {
          final Product product = products[index];
          return Padding(
            padding: EdgeInsets.only(right: index == products.length - 1 ? 0 : 12),
            child: _RecentProductCard(product: product),
          );
        },
      ),
    );
  }
}

class _RecentProductCard extends StatelessWidget {
  const _RecentProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = product.stock == 0;

    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ShadowColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShadowColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(product.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ShadowColors.foreground),
          ),
          const SizedBox(height: 6),
          ShadowBadge(
            label: outOfStock ? 'Out of stock' : '${product.stock} in stock',
            variant: outOfStock ? ShadowBadgeVariant.error : ShadowBadgeVariant.muted,
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const ShadowEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions yet',
        description: 'Sales and purchases will show up here.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (BuildContext context, int index) {
        return _RecentTransactionTile(transaction: transactions[index]);
      },
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({required this.transaction});

  final Transaction transaction;

  ShadowBadgeVariant get _variant {
    switch (transaction.type) {
      case TransactionType.sale:
        return ShadowBadgeVariant.success;
      case TransactionType.purchase:
        return ShadowBadgeVariant.defaultVariant;
      case TransactionType.salesReturn:
        return ShadowBadgeVariant.warning;
      case TransactionType.purchaseReturn:
        return ShadowBadgeVariant.terracotta;
      case TransactionType.adjustment:
        return ShadowBadgeVariant.muted;
    }
  }

  String get _label {
    switch (transaction.type) {
      case TransactionType.sale:
        return 'Sale';
      case TransactionType.purchase:
        return 'Purchase';
      case TransactionType.salesReturn:
        return 'Sales Return';
      case TransactionType.purchaseReturn:
        return 'Purchase Return';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          ShadowBadge(label: _label, variant: _variant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              transaction.entityName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: ShadowColors.foreground),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                Formatters.currency(transaction.grandTotal),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ShadowColors.foreground),
              ),
              Text(
                Formatters.shortDate(transaction.createdAt),
                style: const TextStyle(fontSize: 11, color: ShadowColors.mutedForeground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
