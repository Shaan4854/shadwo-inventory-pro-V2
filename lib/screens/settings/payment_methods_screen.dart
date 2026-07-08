import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late final TextEditingController _methodCtrl;

  @override
  void initState() {
    super.initState();
    _methodCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _methodCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final methods = settings.paymentMethods;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text('Payment Methods', style: ShadowTextStyles.h4),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...AppConstants.paymentMethods.map((m) {
                          final selected = methods.contains(m);
                          return ShadowFilterChip(
                            label: Formatters.capitalize(m),
                            selected: selected,
                            onTap: () => _toggleMethod(m),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShadowInput(
                      label: 'Custom method',
                      controller: _methodCtrl,
                      hint: 'e.g. upi, mobile money',
                      maxLines: 1,
                      onSubmitted: (v) => _addCustom(v),
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

  void _toggleMethod(String method) {
    final provider = context.read<SettingsProvider>();
    final current = provider.settings.paymentMethods;
    final updated = current.contains(method)
        ? current.where((m) => m != method).toList()
        : [...current, method];
    context.read<SettingsProvider>().update(
          provider.settings.copyWith(paymentMethods: updated),
        );
  }

  void _addCustom(String v) {
    final trimmed = v.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    final provider = context.read<SettingsProvider>();
    final current = provider.settings.paymentMethods;
    if (current.contains(trimmed)) {
      _methodCtrl.clear();
      return;
    }
    provider.update(
      provider.settings.copyWith(paymentMethods: [...current, trimmed]),
    );
    _methodCtrl.clear();
  }
}
