import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

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
                    ShadowInput(
                      label: 'Symbol',
                      controller: _symbolCtrl,
                      hint: '\$',
                      maxLines: 1,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                      ],
                      onSubmitted: (_) => _save(),
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
