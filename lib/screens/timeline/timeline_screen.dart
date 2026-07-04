import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/stock_movement.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

enum _Direction { all, inbound, outbound }

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  _Direction _dir = _Direction.all;
  final _searchCtrl = TextEditingController();
  String _search = '';
  DateTime? _from;
  DateTime? _to;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(TransactionProvider provider) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _from = picked.start;
      _to = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
    });
    await provider.load(from: _from, to: _to);
  }

  Iterable<StockMovement> _filter(List<StockMovement> all) {
    Iterable<StockMovement> out = all;
    switch (_dir) {
      case _Direction.all:
        break;
      case _Direction.inbound:
        out = out.where((m) => m.isInbound);
        break;
      case _Direction.outbound:
        out = out.where((m) => m.isOutbound);
        break;
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      out = out.where((m) => m.productName.toLowerCase().contains(q));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final list = _filter(provider.movements).toList(growable: false);
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
            body: RefreshIndicator(
              onRefresh: () => provider.load(from: _from, to: _to),
              color: ShadowColors.primary,
              backgroundColor: ShadowColors.card,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: ShadowPageHeader(
                      title: 'Timeline',
                      subtitle: 'Stock movement history',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ShadowTheme.screenPaddingH,
                      ),
                      child: ShadowSearchBar(
                        controller: _searchCtrl,
                        hint: 'Search by product',
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ShadowTheme.screenPaddingH,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ShadowFilterChip(
                              label: 'All',
                              selected: _dir == _Direction.all,
                              onTap: () =>
                                  setState(() => _dir = _Direction.all),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ShadowFilterChip(
                              label: 'In',
                              icon: Icons.arrow_downward_rounded,
                              selected: _dir == _Direction.inbound,
                              onTap: () =>
                                  setState(() => _dir = _Direction.inbound),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ShadowFilterChip(
                              label: 'Out',
                              icon: Icons.arrow_upward_rounded,
                              selected: _dir == _Direction.outbound,
                              onTap: () =>
                                  setState(() => _dir = _Direction.outbound),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ShadowTheme.screenPaddingH,
                      ),
                      child: Row(
                        children: [
                          if (_from != null && _to != null)
                            Expanded(
                              child: Text(
                                '${Formatters.date(_from!)} — ${Formatters.date(_to!)}',
                                style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            const Expanded(
                              child: Text(
                                'All time',
                                style: ShadowTextStyles.bodyMuted,
                              ),
                            ),
                          ShadowButton(
                            label: 'Filter',
                            variant: ShadowButtonVariant.outline,
                            size: ShadowButtonSize.sm,
                            icon: Icons.date_range_rounded,
                            onPressed: () => _pickDateRange(provider),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (provider.isLoading &&
                      provider.movements.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: SkeletonList.row(count: 6),
                    )
                  else if (list.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ShadowEmptyState(
                        title: 'No movements',
                        subtitle: 'Once you record sales or purchases, they show up here.',
                        icon: Icons.timeline_rounded,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        ShadowTheme.screenPaddingH,
                        0,
                        ShadowTheme.screenPaddingH,
                        24,
                      ),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _MovementRow(m: list[i]),
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

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.m});
  final StockMovement m;

  @override
  Widget build(BuildContext context) {
    final isIn = m.isInbound;
    return ShadowCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isIn
                      ? ShadowColors.accentSage
                      : ShadowColors.destructive)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: isIn ? ShadowColors.accentSage : ShadowColors.destructive,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      m.productEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        m.productName,
                        style: ShadowTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.reason.isEmpty ? m.type.displayLabel : m.reason} · ${Formatters.relative(m.createdAt)}',
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isIn ? '+' : ''}${m.quantityChange}',
            style: ShadowTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: isIn ? ShadowColors.accentSage : ShadowColors.destructive,
            ),
          ),
        ],
      ),
    );
  }
}
