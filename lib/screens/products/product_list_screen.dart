import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/filter_type.dart';
import '../../utils/formatters.dart';
import '../../utils/sort_type.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import 'product_detail_screen.dart';
import 'product_form_sheet.dart';

/// Catalog list — search, filters, sort, tap → detail, FAB → form.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _selectedCategory; // screen-local per Path B carve-out
  final _searchCtrl = TextEditingController();

  /// Guards the stagger animation — true only on the very first build.
  /// Set to false immediately after that build so filter/search rebuilds
  /// don't replay the animation.
  bool _firstBuild = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSort(BuildContext context) async {
    final provider = context.read<ProductProvider>();
    final result = await ShadowBottomSheet.list<SortType>(
      context: context,
      title: 'Sort by',
      items: SortType.values
          .map((s) => ShadowSheetItem(
                label: s.displayLabel,
                value: s,
                icon: provider.selectedSort == s
                    ? Icons.check_rounded
                    : Icons.sort_rounded,
              ))
          .toList(),
    );
    if (result != null && context.mounted) provider.setSort(result);
  }

  Future<void> _openFilter(BuildContext context) async {
    final provider = context.read<ProductProvider>();
    final result = await ShadowBottomSheet.list<FilterType>(
      context: context,
      title: 'Stock filter',
      items: FilterType.values
          .map((f) => ShadowSheetItem(
                label: f.displayLabel,
                value: f,
                icon: provider.selectedFilter == f
                    ? Icons.check_rounded
                    : Icons.filter_alt_outlined,
              ))
          .toList(),
    );
    if (result != null && context.mounted) provider.setFilter(result);
  }

  void _openForm() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(page: const ProductFormSheet()),
    );
  }

  void _openDetail(Product p) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      ShadowAnimations.fadeInUpRoute(
        page: ProductDetailScreen(productId: p.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Capture and immediately clear the first-build flag so rebuilds
    // triggered by search/filter/sort never replay the stagger animation.
    final isFirst = _firstBuild;
    if (_firstBuild) _firstBuild = false;

    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, products, categories, _) {
        var list = products.filteredProducts;
        if (_selectedCategory != null) {
          list = list
              .where((p) => p.category == _selectedCategory)
              .toList(growable: false);
        }
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openForm,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await products.load();
              await categories.load();
            },
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
                    title: 'Products',
                    subtitle: 'Your catalog',
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ShadowTheme.screenPaddingH,
                    ),
                    child: ShadowSearchBar(
                      controller: _searchCtrl,
                      hint: 'Search name, brand, SKU',
                      onChanged: products.setSearch,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _CategoryChips(
                    categories: categories.all
                        .map((c) => c.name)
                        .toList(growable: false),
                    selected: _selectedCategory,
                    onSelect: (c) =>
                        setState(() => _selectedCategory = c),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: _Toolbar(
                    filter: products.selectedFilter,
                    sort: products.selectedSort,
                    onFilter: () => _openFilter(context),
                    onSort: () => _openSort(context),
                    resultCount: list.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                if (products.isLoading && products.all.isEmpty)
                  const SliverFillRemaining(
                    child: SkeletonList.card(count: 4),
                  )
                else if (products.error != null && products.all.isEmpty)
                  SliverFillRemaining(
                    child: ShadowEmptyState(
                      title: "Couldn't load products",
                      subtitle: products.error.toString(),
                      icon: Icons.error_outline_rounded,
                      iconColor: ShadowColors.destructive,
                      actionLabel: 'Retry',
                      onAction: products.load,
                    ),
                  )
                else if (list.isEmpty)
                  SliverFillRemaining(
                    child: ShadowEmptyState(
                      title: 'No products found',
                      subtitle: _selectedCategory != null ||
                              products.search.isNotEmpty ||
                              products.selectedFilter != FilterType.all
                          ? 'Try clearing filters or adjust your search.'
                          : 'Tap "Add Product" to build your catalog.',
                      icon: Icons.inventory_2_outlined,
                      actionLabel: 'Add Product',
                      onAction: _openForm,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      ShadowTheme.screenPaddingH,
                      4,
                      ShadowTheme.screenPaddingH,
                      100,
                    ),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final row = RepaintBoundary(
                          child: _ProductRow(
                            product: list[i],
                            onTap: () => _openDetail(list[i]),
                          ),
                        );
                        // Stagger only on first load, cap delay at item 8
                        // so long lists don't have items animating far
                        // off-screen.
                        if (!isFirst || i > 8) return row;
                        return ShadowAnimations.staggerItem(index: i, child: row);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Category chips ──────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
        padding: const EdgeInsets.symmetric(
          horizontal: ShadowTheme.screenPaddingH,
        ),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return ShadowFilterChip(
              label: 'All',
              selected: selected == null,
              onTap: () => onSelect(null),
            );
          }
          final c = categories[i - 1];
          return ShadowFilterChip(
            label: c,
            selected: selected == c,
            onTap: () => onSelect(c),
          );
        },
      ),
    );
  }
}

// ─── Toolbar ─────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.filter,
    required this.sort,
    required this.onFilter,
    required this.onSort,
    required this.resultCount,
  });

  final FilterType filter;
  final SortType sort;
  final VoidCallback onFilter;
  final VoidCallback onSort;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShadowTheme.screenPaddingH,
        4,
        ShadowTheme.screenPaddingH,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$resultCount ${resultCount == 1 ? 'product' : 'products'}',
              style: ShadowTextStyles.bodyMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ShadowButton(
            label: filter.displayLabel,
            variant: ShadowButtonVariant.outline,
            size: ShadowButtonSize.sm,
            icon: Icons.filter_alt_outlined,
            onPressed: onFilter,
          ),
          const SizedBox(width: 8),
          ShadowButton(
            label: 'Sort',
            variant: ShadowButtonVariant.outline,
            size: ShadowButtonSize.sm,
            icon: Icons.sort_rounded,
            onPressed: onSort,
          ),
        ],
      ),
    );
  }
}

// ─── Product row ─────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  static Widget _avatarFallback(Product p) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ShadowColors.muted,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
      ),
      child: Text(
        p.emoji.isEmpty ? '📦' : p.emoji,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variant = product.isOutOfStock
        ? ShadowBadgeVariant.danger
        : product.isLowStock
            ? ShadowBadgeVariant.warning
            : ShadowBadgeVariant.success;
    final stockLabel = product.isOutOfStock
        ? 'Out of stock'
        : '${product.stock} ${product.unit}';
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            child: product.imagePath.isNotEmpty
                ? Image.file(
                    File(product.imagePath),
                    width: 44,
                    height: 44,
                    // Decode at display size — never load full-res for thumbnail.
                    cacheWidth: 88, // 2× for @2x screens
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(product),
                  )
                : _avatarFallback(product),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: ShadowTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.category.isEmpty
                      ? 'Uncategorized'
                      : product.category,
                  style:
                      ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
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
              ShadowBadge(label: stockLabel, variant: variant),
              const SizedBox(height: 6),
              Text(
                Formatters.currency(product.sellPrice),
                style: ShadowTextStyles.body
                    .copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              _MarginLabel(product: product),
            ],
          ),
        ],
      ),
    );
  }
}

/// Displays margin amount and percentage below the sell price.
class _MarginLabel extends StatelessWidget {
  const _MarginLabel({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final margin = product.sellPrice - product.buyPrice;
    if (product.sellPrice == 0 && product.buyPrice == 0) {
      return const SizedBox.shrink();
    }
    final pct = product.sellPrice > 0
        ? (margin / product.sellPrice * 100)
        : (product.buyPrice > 0 ? (margin / product.buyPrice * 100) : 0.0);
    final color = margin > 0
        ? ShadowColors.accentSage
        : margin < 0
            ? ShadowColors.destructive
            : ShadowColors.mutedForeground;
    final sign = margin > 0 ? '+' : '';
    return Text(
      '$sign${Formatters.currency(margin)}'
      '${pct == 0 && margin == 0 ? '' : ' ($sign${pct.toStringAsFixed(1)}%)'}',
      style: ShadowTextStyles.bodyMuted.copyWith(
        fontSize: 11,
        color: color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
