import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import 'appearance_screen.dart';
import 'backup_restore_screen.dart';
import 'currency_screen.dart';
import 'defaults_screen.dart';
import 'payment_methods_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final s = context.watch<SettingsProvider>().settings;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text('Settings', style: ShadowTextStyles.h4),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              ShadowTheme.screenPaddingH,
              16,
              ShadowTheme.screenPaddingH,
              32,
            ),
            children: [
              ShadowSettingsTile(
                icon: Icons.palette_rounded,
                iconBackground: const Color(0xFF60A5FA),
                title: 'Appearance',
                subtitle: themeController.mode == AppThemeMode.system
                    ? 'System (${themeController.isDark ? "dark" : "light"})'
                    : themeController.mode == AppThemeMode.light
                        ? 'Light mode'
                        : 'Dark mode',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AppearanceScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShadowSettingsTile(
                icon: Icons.attach_money_rounded,
                iconBackground: const Color(0xFF34D399),
                title: 'Currency',
                subtitle: Formatters.currency(100),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CurrencyScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShadowSettingsTile(
                icon: Icons.tune_rounded,
                iconBackground: const Color(0xFFFB923C),
                title: 'Defaults',
                subtitle:
                    'Alert at < ${s.defaultAlertThreshold} \u2022 ${s.defaultUnit}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DefaultsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShadowSettingsTile(
                icon: Icons.payment_rounded,
                iconBackground: const Color(0xFFA78BFA),
                title: 'Payment Methods',
                subtitle: s.paymentMethods
                    .map((m) => m[0].toUpperCase() + m.substring(1))
                    .join(', '),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShadowSettingsTile(
                icon: Icons.backup_rounded,
                iconBackground: const Color(0xFFF87171),
                title: 'Backup & Restore',
                subtitle: 'Export or import your database',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BackupRestoreScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
