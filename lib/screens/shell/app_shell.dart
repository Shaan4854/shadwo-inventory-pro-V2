import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ui_kit/shadow_badge.dart';
import '../../widgets/ui_kit/shadow_bottom_sheet.dart';
import '../../widgets/ui_kit/shadow_divider.dart';
import '../../widgets/ui_kit/shadow_section_label.dart';
import '../customers/customer_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../pos/pos_screen.dart';
import '../products/product_list_screen.dart';
import '../purchase/purchase_screen.dart';
import '../purchase_return/purchase_return_screen.dart';
import '../reports/reports_screen.dart';
import '../sales_return/sales_return_screen.dart';
import '../stock_adjustment/stock_adjustment_screen.dart';
import '../suppliers/supplier_list_screen.dart';
import '../timeline/timeline_screen.dart';
import '../transactions/transactions_screen.dart';

/// Root shell: bottom nav with 4 tabs (state preserved via
/// [IndexedStack]) + a "More" tab that opens a [ShadowBottomSheet]
/// listing the other 8 sections. Navigation state only — no business
/// logic lives here.
class ShadowAppShell extends StatefulWidget {
  const ShadowAppShell({super.key});

  @override
  State<ShadowAppShell> createState() => _ShadowAppShellState();
}

class _ShadowAppShellState extends State<ShadowAppShell> {
  int _tabIndex = 0;

  static const List<Widget> _tabs = <Widget>[
    DashboardScreen(),
    ProductListScreen(),
    PosScreen(),
    PurchaseScreen(),
  ];

  void _selectTab(int index) => setState(() => _tabIndex = index);

  void _openMoreSheet() {
    ShadowBottomSheet.show<void>(
      context: context,
      title: 'More',
      builder: (BuildContext sheetContext) => _MoreSheetContent(
        onSelect: (Widget screen) {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(ShadowAnimation.fadeInUpRoute<void>(screen));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int lowStockCount = context.watch<ProductProvider>().lowStockCount;

    return Scaffold(
      backgroundColor: ShadowColors.background,
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: _ShadowBottomNav(
        currentIndex: _tabIndex,
        productBadgeCount: lowStockCount,
        onTabSelected: _selectTab,
        onMoreTap: _openMoreSheet,
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

const List<_NavItemData> _kNavItems = <_NavItemData>[
  _NavItemData(icon: Icons.home_rounded, label: 'Home'),
  _NavItemData(icon: Icons.inventory_2_rounded, label: 'Products'),
  _NavItemData(icon: Icons.point_of_sale_rounded, label: 'Sell'),
  _NavItemData(icon: Icons.shopping_cart_rounded, label: 'Purchase'),
];

/// Custom-styled bottom nav bar (not the stock [BottomNavigationBar]) —
/// 4 tabs + a 5th "More" item that triggers a sheet instead of a tab.
class _ShadowBottomNav extends StatelessWidget {
  const _ShadowBottomNav({
    required this.currentIndex,
    required this.productBadgeCount,
    required this.onTabSelected,
    required this.onMoreTap,
  });

  final int currentIndex;
  final int productBadgeCount;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: ShadowColors.card),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ShadowDivider(margin: EdgeInsets.zero),
            SizedBox(
              height: 64,
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < _kNavItems.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _kNavItems[i].icon,
                        label: _kNavItems[i].label,
                        active: currentIndex == i,
                        badgeCount: i == 1 ? productBadgeCount : 0,
                        onTap: () => onTabSelected(i),
                      ),
                    ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.more_horiz_rounded,
                      label: 'More',
                      active: false,
                      badgeCount: 0,
                      onTap: onMoreTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? ShadowColors.primary : ShadowColors.mutedForeground;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Icon(icon, color: color, size: 24),
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -10,
                  child: ShadowBadge(
                    label: badgeCount > 99 ? '99+' : '$badgeCount',
                    variant: ShadowBadgeVariant.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Body of the "More" sheet — 8 destinations, grouped under one label.
class _MoreSheetContent extends StatelessWidget {
  const _MoreSheetContent({required this.onSelect});

  final ValueChanged<Widget> onSelect;

  @override
  Widget build(BuildContext context) {
    const List<_NavItemData> items = <_NavItemData>[
      _NavItemData(icon: Icons.people_alt_rounded, label: 'Customers'),
      _NavItemData(icon: Icons.local_shipping_rounded, label: 'Suppliers'),
      _NavItemData(icon: Icons.bar_chart_rounded, label: 'Reports'),
      _NavItemData(icon: Icons.undo_rounded, label: 'Sales Return'),
      _NavItemData(icon: Icons.redo_rounded, label: 'Purchase Return'),
      _NavItemData(icon: Icons.tune_rounded, label: 'Stock Adjustment'),
      _NavItemData(icon: Icons.timeline_rounded, label: 'Timeline'),
      _NavItemData(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    ];

    final List<Widget> screens = <Widget>[
      const CustomerListScreen(),
      const SupplierListScreen(),
      const ReportsScreen(),
      const SalesReturnScreen(),
      const PurchaseReturnScreen(),
      const StockAdjustmentScreen(),
      const TimelineScreen(),
      const TransactionsScreen(),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ShadowSectionLabel('More Options'),
          for (int i = 0; i < items.length; i++)
            _MoreSheetRow(
              icon: items[i].icon,
              label: items[i].label,
              onTap: () => onSelect(screens[i]),
            ),
        ],
      ),
    );
  }
}

class _MoreSheetRow extends StatelessWidget {
  const _MoreSheetRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: ShadowColors.mutedForeground),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ShadowColors.foreground,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 18, color: ShadowColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
