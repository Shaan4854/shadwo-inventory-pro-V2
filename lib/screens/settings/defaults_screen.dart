import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/ui_kit/ui_kit.dart';

class DefaultsScreen extends StatefulWidget {
  const DefaultsScreen({super.key});

  @override
  State<DefaultsScreen> createState() => _DefaultsScreenState();
}

class _DefaultsScreenState extends State<DefaultsScreen> {
  late final TextEditingController _thresholdCtrl;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _thresholdCtrl = TextEditingController(
      text: settings.defaultAlertThreshold.toString(),
    );
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final unit = settings.defaultUnit;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text('Defaults', style: ShadowTextStyles.h4),
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
                      label: 'Default low-stock threshold',
                      controller: _thresholdCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) => _saveThreshold(),
                    ),
                    const SizedBox(height: 16),
                    Text('Default unit', style: ShadowTextStyles.caption),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: AppConstants.units.map((u) {
                        return ShadowFilterChip(
                          label: u,
                          selected: unit == u,
                          onTap: () => _setUnit(u),
                        );
                      }).toList(),
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

  void _saveThreshold() {
    final raw = _thresholdCtrl.text.trim();
    final threshold = int.tryParse(raw);
    if (threshold == null || threshold < 0) return;
    final provider = context.read<SettingsProvider>();
    final current = provider.settings;
    if (threshold == current.defaultAlertThreshold) return;
    provider.update(current.copyWith(defaultAlertThreshold: threshold));
  }

  void _setUnit(String u) {
    final provider = context.read<SettingsProvider>();
    final current = provider.settings;
    if (u == current.defaultUnit) return;
    provider.update(current.copyWith(defaultUnit: u));
  }
}
