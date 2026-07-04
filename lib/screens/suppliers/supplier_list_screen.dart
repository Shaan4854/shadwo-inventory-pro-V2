import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/supplier.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../_shared/entity_form_sheet.dart';
import 'supplier_detail_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _add() {
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(
        page: const EntityFormSheet(kind: EntityKind.supplier),
      ),
    );
  }

  void _open(Supplier s) {
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(
        page: SupplierDetailScreen(supplierId: s.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(
      builder: (context, provider, _) {
        final list = provider.filtered;
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
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.local_shipping_rounded),
              label: const Text('Add supplier'),
            ),
            body: RefreshIndicator(
              onRefresh: provider.load,
              color: ShadowColors.primary,
              backgroundColor: ShadowColors.card,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: ShadowPageHeader(
                      title: 'Suppliers',
                      subtitle: 'Your supplier directory',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ShadowTheme.screenPaddingH,
                      ),
                      child: ShadowSearchBar(
                        controller: _searchCtrl,
                        hint: 'Search name, contact, mobile',
                        onChanged: provider.setSearch,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (provider.isLoading && provider.all.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: SkeletonList.card(count: 4),
                    )
                  else if (provider.error != null && provider.all.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ShadowEmptyState(
                        title: "Couldn't load suppliers",
                        subtitle: provider.error.toString(),
                        icon: Icons.error_outline_rounded,
                        iconColor: ShadowColors.destructive,
                        actionLabel: 'Retry',
                        onAction: provider.load,
                      ),
                    )
                  else if (list.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ShadowEmptyState(
                        title: 'No suppliers yet',
                        subtitle:
                            'Add a supplier to track where your inventory comes from.',
                        icon: Icons.local_shipping_outlined,
                        actionLabel: 'Add supplier',
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
                        itemBuilder: (context, i) => _SupplierRow(
                          supplier: list[i],
                          onTap: () => _open(list[i]),
                        ),
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

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({required this.supplier, required this.onTap});
  final Supplier supplier;
  final VoidCallback onTap;

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
            decoration: const BoxDecoration(
              color: ShadowColors.muted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: ShadowColors.foreground,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  supplier.name,
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (supplier.contactPerson.isNotEmpty)
                      supplier.contactPerson,
                    if (supplier.mobile.isNotEmpty) supplier.mobile,
                  ].join(' · '),
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (supplier.outstandingBalance > 0) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Owed', style: ShadowTextStyles.caption),
                Text(
                  Formatters.currency(supplier.outstandingBalance),
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ShadowColors.destructive,
                  ),
                ),
              ],
            ),
          ],
          const Icon(Icons.chevron_right_rounded,
              color: ShadowColors.mutedForeground),
        ],
      ),
    );
  }
}
