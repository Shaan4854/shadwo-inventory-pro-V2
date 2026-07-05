import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../providers/reports_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/export_helper.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Getter (not a static field) so the pie colors track the active palette
  // when the user switches light/dark mode.
  List<Color> get _pieColors => <Color>[
        ShadowColors.accentDefault,
        ShadowColors.accentSage,
        ShadowColors.accentOlive,
        ShadowColors.accentTerracotta,
        ShadowColors.accentWarning,
        ShadowColors.accent,
        ShadowColors.destructive,
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReportsProvider>().load();
    });
  }

  Future<void> _pickRange(BuildContext context, ReportsProvider p) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: p.from, end: p.to),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: ShadowColors.primary,
            onPrimary: ShadowColors.primaryFg,
            surface: ShadowColors.card,
            onSurface: ShadowColors.foreground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) p.setRange(from: picked.start, to: picked.end);
  }

  Future<void> _exportExcel(BuildContext context, ReportsProvider p) async {
    try {
      final bytes = await ExportHelper.buildReportExcel(p);
      await ExportHelper.saveAndShareExcel(bytes, 'report');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
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
              actions: [
                IconButton(
                  tooltip: 'Date range',
                  icon: const Icon(Icons.date_range_rounded),
                  onPressed: () => _pickRange(context, provider),
                ),
                IconButton(
                  tooltip: 'Export Excel',
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () => _exportExcel(context, provider),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: provider.load,
              color: ShadowColors.primary,
              backgroundColor: ShadowColors.card,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  ShadowPageHeader(
                    title: 'Reports',
                    subtitle:
                        '${Formatters.date(provider.from)} — ${Formatters.date(provider.to)}',
                  ),
                  if (provider.isLoading &&
                      provider.transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: ShadowColors.primary,
                        ),
                      ),
                    )
                  else ...[
                    RepaintBoundary(child: _StatsRow(provider: provider)),
                    const SizedBox(height: ShadowTheme.gapSection),
                    RepaintBoundary(child: _SalesByDayCard(provider: provider)),
                    const SizedBox(height: ShadowTheme.gapSection),
                    RepaintBoundary(child: _TopProductsCard(provider: provider)),
                    const SizedBox(height: ShadowTheme.gapSection),
                    RepaintBoundary(
                      child: _CategoryPieCard(
                        provider: provider,
                        colors: _pieColors,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.provider});
  final ReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, Color accent) => Expanded(
          child: ShadowStatCard(
            label: label,
            value: value,
            accent: accent,
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
      ),
      child: Column(
        children: [
          Row(
            children: [
              cell(
                'Revenue',
                Formatters.currency(provider.totalRevenue),
                ShadowColors.accentSage,
              ),
              const SizedBox(width: ShadowTheme.gapCard),
              cell(
                'Expenses (COGS)',
                Formatters.currency(provider.totalExpenses),
                ShadowColors.accentTerracotta,
              ),
            ],
          ),
          const SizedBox(height: ShadowTheme.gapCard),
          Row(
            children: [
              cell(
                'Net profit',
                Formatters.currency(provider.netProfit),
                ShadowColors.accentDefault,
              ),
              const SizedBox(width: ShadowTheme.gapCard),
              cell(
                'Sales count',
                '${provider.salesCount}',
                ShadowColors.accentOlive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesByDayCard extends StatelessWidget {
  const _SalesByDayCard({required this.provider});
  final ReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    final data = provider.salesByDay;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
      ),
      child: ShadowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShadowSectionLabel('Sales by day'),
            const SizedBox(height: 16),
            if (data.every((e) => e.value == 0))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No sales in this range.',
                    style: ShadowTextStyles.bodyMuted,
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: ShadowColors.border.withValues(alpha: 0.4),
                        strokeWidth: 0.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, meta) => Text(
                            Formatters.compact(v),
                            style: ShadowTextStyles.bodyMuted
                                .copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: (data.length / 4).ceilToDouble() < 1
                              ? 1
                              : (data.length / 4).ceilToDouble(),
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= data.length) {
                              return const SizedBox.shrink();
                            }
                            final d = data[i].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${d.day}/${d.month}',
                                style: ShadowTextStyles.bodyMuted
                                    .copyWith(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: ShadowColors.primary,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              ShadowColors.primary.withValues(alpha: 0.15),
                        ),
                        spots: [
                          for (var i = 0; i < data.length; i++)
                            FlSpot(i.toDouble(), data[i].value),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.provider});
  final ReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    final data = provider.topProductsByRevenue();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
      ),
      child: ShadowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShadowSectionLabel('Top products'),
            const SizedBox(height: 12),
            if (data.isEmpty)
              Text('No sales yet.', style: ShadowTextStyles.bodyMuted)
            else
              ...data.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: ShadowTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.currency(e.value),
                        style: ShadowTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ShadowColors.accentSage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({required this.provider, required this.colors});
  final ReportsProvider provider;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final data = provider.revenueByCategory;
    final total = data.values.fold<double>(0, (s, v) => s + v);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadowTheme.screenPaddingH,
      ),
      child: ShadowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShadowSectionLabel('Revenue by category'),
            const SizedBox(height: 12),
            if (data.isEmpty || total == 0)
              Text('No revenue yet.', style: ShadowTextStyles.bodyMuted)
            else
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                          sections: [
                            for (var i = 0; i < data.length; i++)
                              PieChartSectionData(
                                color: colors[i % colors.length],
                                value: data.values.elementAt(i),
                                title: '',
                                radius: 34,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (var i = 0; i < data.length; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color:
                                          colors[i % colors.length],
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      data.keys.elementAt(i),
                                      style: ShadowTextStyles.body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${((data.values.elementAt(i) / total) * 100).toStringAsFixed(0)}%',
                                    style: ShadowTextStyles.bodyMuted
                                        .copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
