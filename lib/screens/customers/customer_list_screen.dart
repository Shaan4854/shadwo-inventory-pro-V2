import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../_shared/entity_form_sheet.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchCtrl = TextEditingController();
  bool _firstBuild = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _add() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(
        page: const EntityFormSheet(kind: EntityKind.customer),
      ),
    );
  }

  void _open(Customer c) {
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(
        page: CustomerDetailScreen(customerId: c.id),
      ),
    );
  }

  Future<void> _delete(Customer c) async {
    final ok = await ShadowConfirmDialog.show(
      context,
      title: 'Delete customer?',
      message: '"${c.name}" will be removed.',
      danger: true,
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    await context.read<CustomerProvider>().deleteCustomer(c.id);
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _firstBuild;
    if (_firstBuild) _firstBuild = false;

    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        final list = provider.filtered;
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
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Add customer'),
            ),
            body: RefreshIndicator(
              onRefresh: provider.load,
              color: ShadowColors.primary,
              backgroundColor: ShadowColors.card,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
                slivers: [
                  const SliverToBoxAdapter(
                    child: ShadowPageHeader(
                      title: 'Customers',
                      subtitle: 'Your customer directory',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ShadowTheme.screenPaddingH,
                      ),
                      child: ShadowSearchBar(
                        controller: _searchCtrl,
                        hint: 'Search name, mobile, email',
                        onChanged: provider.setSearch,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (provider.isLoading && provider.all.isEmpty)
                    const SliverFillRemaining(
                      child: SkeletonList.card(count: 4),
                    )
                  else if (provider.error != null && provider.all.isEmpty)
                    SliverFillRemaining(
                      child: ShadowEmptyState(
                        title: "Couldn't load customers",
                        subtitle: provider.error.toString(),
                        icon: Icons.error_outline_rounded,
                        iconColor: ShadowColors.destructive,
                        actionLabel: 'Retry',
                        onAction: provider.load,
                      ),
                    )
                  else if (list.isEmpty)
                    SliverFillRemaining(
                      child: ShadowEmptyState(
                        title: 'No customers yet',
                        subtitle:
                            'Add your first customer to keep track of who you sell to.',
                        icon: Icons.people_alt_outlined,
                        actionLabel: 'Add customer',
                        onAction: _add,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        ShadowTheme.screenPaddingH,
                        0,
                        ShadowTheme.screenPaddingH,
                        100,
                      ),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final row = RepaintBoundary(
                            child: _CustomerRow(
                              customer: list[i],
                              onTap: () => _open(list[i]),
                              onDelete: () => _delete(list[i]),
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

// ─── Customer row ─────────────────────────────────────────────────────

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.onTap,
    required this.onDelete,
  });
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ShadowColors.muted,
              shape: BoxShape.circle,
            ),
            child: Text(
              customer.name.isEmpty
                  ? '?'
                  : customer.name.substring(0, 1).toUpperCase(),
              style: ShadowTextStyles.h4,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.titleCase(customer.name),
                  style: ShadowTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (customer.mobile.isNotEmpty) customer.mobile,
                    if (customer.email.isNotEmpty) customer.email,
                  ].join(' · '),
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (customer.outstandingBalance != 0) ...[
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customer.outstandingBalance > 0 ? 'Owes' : 'Credit',
                  style: ShadowTextStyles.caption,
                ),
                Text(
                  Formatters.currency(customer.outstandingBalance.abs()),
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: customer.outstandingBalance > 0
                        ? ShadowColors.destructive
                        : ShadowColors.accentSage,
                  ),
                ),
              ],
            ),
          ],
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: ShadowColors.mutedForeground,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
