import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../customers/customer_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../pos/pos_screen.dart';
import '../products/product_list_screen.dart';
import '../purchase/purchase_screen.dart';
import '../reports/reports_screen.dart';
import '../sales_return/sales_return_screen.dart';
import '../stock_adjustment/stock_adjustment_screen.dart';
import '../suppliers/supplier_list_screen.dart';
import '../timeline/timeline_screen.dart';
import '../transactions/transactions_screen.dart';
import '../purchase_return/purchase_return_screen.dart';

/// Root shell with a custom bottom nav (NOT `BottomNavigationBar`).
/// Uses an `IndexedStack` over the 4 primary tabs so each preserves
/// scroll + form state when the user switches away and back.
///
/// Tab switch plays a 150 ms opacity crossfade on the newly-selected tab
/// (the outgoing tab stays rendered since IndexedStack keeps all alive).
/// Each switch fires [HapticFeedback.selectionClick].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = <_TabDef>[
    _TabDef(icon: Icons.home_rounded, label: 'Home'),
    _TabDef(icon: Icons.inventory_2_outlined, label: 'Products'),
    _TabDef(icon: Icons.point_of_sale_rounded, label: 'Sell'),
    _TabDef(icon: Icons.shopping_cart_outlined, label: 'Purchase'),
    _TabDef(icon: Icons.more_horiz_rounded, label: 'More'),
  ];

  void _onTap(int i) async {
    if (i == 4) {
      final selected = await ShadowBottomSheet.list<_MoreDestination>(
        context: context,
        title: 'More',
        items: const [
          ShadowSheetItem(
            label: 'Customers',
            value: _MoreDestination.customers,
            icon: Icons.people_alt_outlined,
          ),
          ShadowSheetItem(
            label: 'Suppliers',
            value: _MoreDestination.suppliers,
            icon: Icons.local_shipping_outlined,
          ),
          ShadowSheetItem(
            label: 'Reports',
            value: _MoreDestination.reports,
            icon: Icons.insert_chart_outlined_rounded,
          ),
          ShadowSheetItem(
            label: 'Sales Return',
            value: _MoreDestination.salesReturn,
            icon: Icons.assignment_return_outlined,
          ),
          ShadowSheetItem(
            label: 'Purchase Return',
            value: _MoreDestination.purchaseReturn,
            icon: Icons.keyboard_return_rounded,
          ),
          ShadowSheetItem(
            label: 'Stock Adjustment',
            value: _MoreDestination.stockAdjustment,
            icon: Icons.tune_rounded,
          ),
          ShadowSheetItem(
            label: 'Timeline',
            value: _MoreDestination.timeline,
            icon: Icons.timeline_rounded,
          ),
          ShadowSheetItem(
            label: 'Transactions',
            value: _MoreDestination.transactions,
            icon: Icons.receipt_long_outlined,
          ),
        ],
      );
      if (selected == null || !mounted) return;
      Navigator.of(context).push(_routeFor(selected));
      return;
    }
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  Route<Object?> _routeFor(_MoreDestination d) {
    switch (d) {
      case _MoreDestination.customers:
        return _fadeRoute(const CustomerListScreen());
      case _MoreDestination.suppliers:
        return _fadeRoute(const SupplierListScreen());
      case _MoreDestination.reports:
        return _fadeRoute(const ReportsScreen());
      case _MoreDestination.salesReturn:
        return _fadeRoute(const SalesReturnScreen());
      case _MoreDestination.purchaseReturn:
        return _fadeRoute(const PurchaseReturnScreen());
      case _MoreDestination.stockAdjustment:
        return _fadeRoute(const StockAdjustmentScreen());
      case _MoreDestination.timeline:
        return _fadeRoute(const TimelineScreen());
      case _MoreDestination.transactions:
        return _fadeRoute(const TransactionsScreen());
    }
  }

  Route<Object?> _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 20),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              _FadeTab(active: _index == 0, child: const DashboardScreen()),
              _FadeTab(active: _index == 1, child: const ProductListScreen()),
              _FadeTab(active: _index == 2, child: const PosScreen()),
              _FadeTab(active: _index == 3, child: const PurchaseScreen()),
            ],
          ),
        ),
        // Selector scoped to lowStockCount only — no rebuild on unrelated
        // product changes (name edits, price updates, etc.).
        bottomNavigationBar: Selector<ProductProvider, int>(
          selector: (_, pp) => pp.lowStockCount,
          builder: (context, lowCount, _) => _BottomBar(
            tabs: _tabs,
            activeIndex: _index,
            onTap: _onTap,
            productBadge: lowCount,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Crossfade wrapper for each IndexedStack child.
// Animates opacity 0→1 when a tab becomes active (150 ms, easeOut).
// The outgoing tab stays at opacity 1 since it remains mounted in the stack.
// ---------------------------------------------------------------------------
class _FadeTab extends StatelessWidget {
  const _FadeTab({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------

enum _MoreDestination {
  customers,
  suppliers,
  reports,
  salesReturn,
  purchaseReturn,
  stockAdjustment,
  timeline,
  transactions,
}

class _TabDef {
  const _TabDef({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
    this.productBadge = 0,
  });

  final List<_TabDef> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final int productBadge;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ShadowColors.card,
          border: Border(
            top: BorderSide(color: ShadowColors.border, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    tab: tabs[i],
                    active: i == activeIndex,
                    onTap: () => onTap(i),
                    badge: i == 1 && productBadge > 0 ? productBadge : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final _TabDef tab;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? ShadowColors.primary : ShadowColors.mutedForeground;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(tab.icon, size: 22, color: color),
                  if (badge != null)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: ShadowColors.destructive,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: ShadowTextStyles.body.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
