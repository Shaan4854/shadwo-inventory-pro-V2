import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late final TextEditingController _methodCtrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _methodCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _methodCtrl.dispose();
    _focusNode.dispose();
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
                        ...methods.map((m) {
                          return ShadowFilterChip(
                            label: Formatters.capitalize(m),
                            selected: true,
                            onTap: () => _removeMethod(m),
                          );
                        }),
                      ],
                    ),
                    if (methods.isNotEmpty) const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ShadowInput(
                            label: 'Add method',
                            controller: _methodCtrl,
                            hint: 'e.g. upi, mobile money',
                            maxLines: 1,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (v) => _addCustom(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: Material(
                            color: ShadowColors.primary,
                            borderRadius: BorderRadius.circular(
                              ShadowTheme.radiusMd,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                ShadowTheme.radiusMd,
                              ),
                              onTap: () {
                                _addCustom(_methodCtrl.text);
                                _focusNode.unfocus();
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _removeMethod(String method) {
    final provider = context.read<SettingsProvider>();
    final current = provider.settings.paymentMethods;
    final updated = current.where((m) => m != method).toList();
    provider.update(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Formatters.capitalize(trimmed)} already exists'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    provider.update(
      provider.settings.copyWith(paymentMethods: [...current, trimmed]),
    );
    _methodCtrl.clear();
    _focusNode.unfocus();
  }
}
