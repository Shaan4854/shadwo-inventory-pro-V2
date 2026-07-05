import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

  Future<void> _delete(Supplier s) async {
    final ok = await ShadowConfirmDialog.show(
      context,
      title: 'Delete supplier?',
      message: '"${s.name}" will be removed.',
      danger: true,
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    await context.read<SupplierProvider>().deleteSupplier(s.id);
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _firstBuild;
    if (_firstBuild) _firstBuild = false;

    return Consumer<SupplierProvider>(
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
              icon: const Icon(Icons.local_shipping_rounded),
              label: const Text('Add supplier'),
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
                      child: SkeletonList.card(count: 4),
                    )
                  else if (provider.error != null && provider.all.isEmpty)
                    SliverFillRemaining(
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
                        itemBuilder: (context, i) {
                          final row = RepaintBoundary(
                            child: _SupplierRow(
                              supplier: list[i],
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

// ─── Supplier row ─────────────────────────────────────────────────────

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.supplier,
    required this.onTap,
    required this.onDelete,
  });
  final Supplier supplier;
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
            child: Icon(
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
                  style: ShadowTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (supplier.outstandingBalance != 0) ...[
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  supplier.outstandingBalance > 0 ? 'Owed' : 'Credit',
                  style: ShadowTextStyles.caption,
                ),
                Text(
                  Formatters.currency(supplier.outstandingBalance.abs()),
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: supplier.outstandingBalance > 0
                        ? ShadowColors.accentTerracotta
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
