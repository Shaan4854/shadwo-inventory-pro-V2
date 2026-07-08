import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

class _CurrencyOption {
  const _CurrencyOption(
    this.flag,
    this.country,
    this.code,
    this.symbol,
    this.position,
  );
  final String flag;
  final String country;
  final String code;
  final String symbol;
  final String position;
}

const _currencyOptions = [
  _CurrencyOption('\u{1F1FA}\u{1F1F8}', 'United States', 'USD', '\$', 'left'),
  _CurrencyOption('\u{1F1EE}\u{1F1F3}', 'India', 'INR', '\u{20B9}', 'left'),
  _CurrencyOption('\u{1F1EC}\u{1F1E7}', 'United Kingdom', 'GBP', '\u{00A3}', 'left'),
  _CurrencyOption('\u{1F1EA}\u{1F1FA}', 'Europe', 'EUR', '\u{20AC}', 'left'),
  _CurrencyOption('\u{1F1EF}\u{1F1F5}', 'Japan', 'JPY', '\u{00A5}', 'left'),
  _CurrencyOption('\u{1F1E8}\u{1F1F3}', 'China', 'CNY', '\u{00A5}', 'left'),
  _CurrencyOption('\u{1F1E6}\u{1F1FA}', 'Australia', 'AUD', 'A\$', 'left'),
  _CurrencyOption('\u{1F1E8}\u{1F1E6}', 'Canada', 'CAD', 'C\$', 'left'),
  _CurrencyOption('\u{1F1F0}\u{1F1F7}', 'South Korea', 'KRW', '\u{20A9}', 'left'),
  _CurrencyOption('\u{1F1E7}\u{1F1F7}', 'Brazil', 'BRL', 'R\$', 'left'),
  _CurrencyOption('\u{1F1E6}\u{1F1F1}', 'Argentina', 'ARS', '\$', 'left'),
  _CurrencyOption('\u{1F1E9}\u{1F1EA}', 'Germany', 'EUR', '\u{20AC}', 'left'),
  _CurrencyOption('\u{1F1EB}\u{1F1F7}', 'France', 'EUR', '\u{20AC}', 'left'),
  _CurrencyOption('\u{1F1EE}\u{1F1F9}', 'Indonesia', 'IDR', 'Rp', 'left'),
  _CurrencyOption('\u{1F1F2}\u{1F1FE}', 'Malaysia', 'MYR', 'RM', 'left'),
  _CurrencyOption('\u{1F1F3}\u{1F1F1}', 'Nigeria', 'NGN', '\u{20A6}', 'left'),
  _CurrencyOption('\u{1F1F5}\u{1F1F0}', 'Pakistan', 'PKR', '\u{20A8}', 'left'),
  _CurrencyOption('\u{1F1F8}\u{1F1EC}', 'Saudi Arabia', 'SAR', '\u{FDFC}', 'left'),
  _CurrencyOption('\u{1F1F8}\u{1F1F4}', 'Singapore', 'SGD', 'S\$', 'left'),
  _CurrencyOption('\u{1F1F0}\u{1F1F7}', 'South Africa', 'ZAR', 'R', 'left'),
  _CurrencyOption('\u{1F1F0}\u{1F1FC}', 'Switzerland', 'CHF', 'CHF', 'left'),
  _CurrencyOption('\u{1F1F9}\u{1F1ED}', 'Thailand', 'THB', '\u{0E3F}', 'left'),
  _CurrencyOption('\u{1F1E6}\u{1F1EA}', 'UAE', 'AED', '\u{062F}.\u{0625}', 'left'),
  _CurrencyOption('\u{1F1FB}\u{1F1F3}', 'Vietnam', 'VND', '\u{20AB}', 'left'),
  _CurrencyOption('\u{1F1F7}\u{1F1FA}', 'Russia', 'RUB', '\u{20BD}', 'left'),
  _CurrencyOption('\u{1F1F2}\u{1F1E6}', 'Mexico', 'MXN', 'MX\$', 'left'),
];

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late final TextEditingController _symbolCtrl;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _symbolCtrl = TextEditingController(text: settings.currencySymbol);
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final position = settings.currencyPosition;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text('Currency', style: ShadowTextStyles.h4),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              ShadowTheme.screenPaddingH,
              8,
              ShadowTheme.screenPaddingH,
              32,
            ),
            children: [
              const SizedBox(height: 12),
              ShadowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CurrencySelectorTile(
                      currentSymbol: settings.currencySymbol,
                      onSelected: _applyCurrencyOption,
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: ShadowColors.border,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ShadowInput(
                            label: 'Symbol',
                            controller: _symbolCtrl,
                            hint: '\$',
                            maxLines: 1,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(5),
                            ],
                            onSubmitted: (_) => _save(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShadowButton(
                          label: 'Update',
                          size: ShadowButtonSize.sm,
                          onPressed: _save,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Position', style: ShadowTextStyles.caption),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ShadowFilterChip(
                            label: 'Left (\$100)',
                            selected: position == 'left',
                            onTap: () => _setPosition('left'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ShadowFilterChip(
                            label: 'Right (100 \$)',
                            selected: position == 'right',
                            onTap: () => _setPosition('right'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ShadowColors.muted.withValues(alpha: 0.3),
                        borderRadius:
                            BorderRadius.circular(ShadowTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Text('Preview: ', style: ShadowTextStyles.bodyMuted),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.currency(1234.56),
                            style: ShadowTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  void _applyCurrencyOption(_CurrencyOption opt) {
    final provider = context.read<SettingsProvider>();
    final current = provider.settings;
    if (opt.symbol == current.currencySymbol && opt.position == current.currencyPosition) return;
    _symbolCtrl.text = opt.symbol;
    provider.update(
      current.copyWith(
        currencySymbol: opt.symbol,
        currencyPosition: opt.position,
      ),
    );
  }

  void _setPosition(String pos) {
    final provider = context.read<SettingsProvider>();
    final current = provider.settings;
    if (pos == current.currencyPosition) return;
    provider.update(current.copyWith(currencyPosition: pos));
  }

  void _save() {
    final symbol = _symbolCtrl.text.trim();
    if (symbol.isEmpty) return;
    final provider = context.read<SettingsProvider>();
    final current = provider.settings;
    if (symbol == current.currencySymbol) return;
    provider.update(current.copyWith(currencySymbol: symbol));
  }
}

class _CurrencySelectorTile extends StatelessWidget {
  const _CurrencySelectorTile({
    required this.currentSymbol,
    required this.onSelected,
  });

  final String currentSymbol;
  final ValueChanged<_CurrencyOption> onSelected;

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ShadowColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ShadowColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Select Currency',
                        style: ShadowTextStyles.h4,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: ShadowColors.mutedForeground,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 0.5, color: ShadowColors.border),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _currencyOptions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 60,
                      color: ShadowColors.border,
                    ),
                    itemBuilder: (_, i) {
                      final opt = _currencyOptions[i];
                      final selected = opt.symbol == currentSymbol;
                      return ListTile(
                        leading: Text(opt.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          '${opt.country} (${opt.code})',
                          style: ShadowTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${opt.symbol} \u2022 ${opt.position == 'left' ? 'Symbol before' : 'Symbol after'}',
                          style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: ShadowColors.primary,
                                size: 22,
                              )
                            : null,
                        onTap: () {
                          onSelected(opt);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
        onTap: () => _openPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Text(
                'Select Currency',
                style: ShadowTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                currentSymbol,
                style: ShadowTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ShadowColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: ShadowColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
