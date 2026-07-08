import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../providers/category_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/backup_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';

enum _Section { appearance, currency, defaults, payment, backup }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Section? _openSection;
  bool _busy = false;

  void _toggle(_Section s) {
    HapticFeedback.selectionClick();
    setState(() => _openSection = _openSection == s ? null : s);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final settings = context.watch<SettingsProvider>().settings;
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
              8,
              ShadowTheme.screenPaddingH,
              32,
            ),
            children: [
              const SizedBox(height: 12),
              ShadowExpandableCard(
                icon: Icons.palette_rounded,
                title: 'Appearance',
                subtitle: themeController.mode == AppThemeMode.system
                    ? 'System (${themeController.isDark ? "dark" : "light"})'
                    : themeController.mode == AppThemeMode.light
                        ? 'Light mode'
                        : 'Dark mode',
                isExpanded: _openSection == _Section.appearance,
                onTap: () => _toggle(_Section.appearance),
                body: _AppearanceBody(themeController: themeController),
              ),
              const SizedBox(height: 12),
              ShadowExpandableCard(
                icon: Icons.attach_money_rounded,
                title: 'Currency',
                subtitle: Formatters.currency(100),
                isExpanded: _openSection == _Section.currency,
                onTap: () => _toggle(_Section.currency),
                body: _CurrencyBody(settings: settings),
              ),
              const SizedBox(height: 12),
              ShadowExpandableCard(
                icon: Icons.tune_rounded,
                title: 'Defaults',
                subtitle:
                    'Alert at < ${settings.defaultAlertThreshold} \u2022 ${settings.defaultUnit}',
                isExpanded: _openSection == _Section.defaults,
                onTap: () => _toggle(_Section.defaults),
                body: _DefaultsBody(settings: settings),
              ),
              const SizedBox(height: 12),
              ShadowExpandableCard(
                icon: Icons.payment_rounded,
                title: 'Payment Methods',
                subtitle: settings.paymentMethods
                    .map((m) => m[0].toUpperCase() + m.substring(1))
                    .join(', '),
                isExpanded: _openSection == _Section.payment,
                onTap: () => _toggle(_Section.payment),
                body: _PaymentBody(settings: settings),
              ),
              const SizedBox(height: 12),
              ShadowExpandableCard(
                icon: Icons.backup_rounded,
                title: 'Backup & Restore',
                subtitle: 'Export or import your database',
                isExpanded: _openSection == _Section.backup,
                onTap: () => _toggle(_Section.backup),
                body: _BackupBody(
                  busy: _busy,
                  onBackup: _onBackup,
                  onRestore: _onRestore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onBackup() async {
    setState(() => _busy = true);
    try {
      await BackupService.backup();
      if (!mounted) return;
      _showSuccess('Backup exported successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRestore() async {
    final path = await BackupService.pickFile();
    if (path == null || !mounted) return;

    final confirmed = await ShadowConfirmDialog.show(
      context,
      title: 'Restore Backup?',
      message: 'This will replace ALL current data with the backup. '
          'This action cannot be undone.',
      confirmLabel: 'Restore',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final ok = await BackupService.restore(path);
      if (!mounted) return;
      if (!ok) {
        _showError('Invalid backup file');
        return;
      }
      await Future.wait([
        context.read<ProductProvider>().load(),
        context.read<CategoryProvider>().load(),
        context.read<CustomerProvider>().load(),
        context.read<SupplierProvider>().load(),
        context.read<TransactionProvider>().load(),
        context.read<ReportsProvider>().load(),
      ]);
      if (!mounted) return;
      _showSuccess('Data restored successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ShadowColors.destructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ────────────────────────────────────────────── Appearance body ──

class _AppearanceBody extends StatelessWidget {
  const _AppearanceBody({required this.themeController});
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _ModeTile(
          icon: Icons.light_mode_rounded,
          title: 'Light',
          subtitle: 'Bright, high-contrast surfaces',
          selected: themeController.mode == AppThemeMode.light,
          onTap: () => themeController.setMode(AppThemeMode.light),
        ),
        _ModeTile(
          icon: Icons.dark_mode_rounded,
          title: 'Dark',
          subtitle: 'Deep navy glass -- easy on the eyes',
          selected: themeController.mode == AppThemeMode.dark,
          onTap: () => themeController.setMode(AppThemeMode.dark),
        ),
        _ModeTile(
          icon: Icons.brightness_auto_rounded,
          title: 'System',
          subtitle: 'Follow your device setting',
          selected: themeController.mode == AppThemeMode.system,
          onTap: () => themeController.setMode(AppThemeMode.system),
          showDivider: false,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            themeController.mode == AppThemeMode.system
                ? 'Currently showing ${themeController.isDark ? 'dark' : 'light'} to match your device.'
                : 'You can also tap the sun/moon icon in any screen header to switch instantly.',
            style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────── Currency body ──

class _CurrencyBody extends StatefulWidget {
  const _CurrencyBody({required this.settings});
  final AppSettings settings;

  @override
  State<_CurrencyBody> createState() => _CurrencyBodyState();
}

class _CurrencyBodyState extends State<_CurrencyBody> {
  late final TextEditingController _symbolCtrl;

  @override
  void initState() {
    super.initState();
    _symbolCtrl = TextEditingController(text: widget.settings.currencySymbol);
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.settings.currencyPosition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
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
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
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
    );
  }

  void _setPosition(String pos) {
    if (pos == widget.settings.currencyPosition) return;
    context.read<SettingsProvider>().update(
          widget.settings.copyWith(currencyPosition: pos),
        );
  }

  void _save() {
    final symbol = _symbolCtrl.text.trim();
    if (symbol.isEmpty || symbol == widget.settings.currencySymbol) return;
    context.read<SettingsProvider>().update(
          widget.settings.copyWith(currencySymbol: symbol),
        );
  }
}

// ──────────────────────────────────────────────── Defaults body ──

class _DefaultsBody extends StatefulWidget {
  const _DefaultsBody({required this.settings});
  final AppSettings settings;

  @override
  State<_DefaultsBody> createState() => _DefaultsBodyState();
}

class _DefaultsBodyState extends State<_DefaultsBody> {
  late final TextEditingController _thresholdCtrl;

  @override
  void initState() {
    super.initState();
    _thresholdCtrl = TextEditingController(
      text: widget.settings.defaultAlertThreshold.toString(),
    );
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.settings.defaultUnit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
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
    );
  }

  void _saveThreshold() {
    final raw = _thresholdCtrl.text.trim();
    final threshold = int.tryParse(raw);
    if (threshold == null || threshold < 0) return;
    if (threshold == widget.settings.defaultAlertThreshold) return;
    context.read<SettingsProvider>().update(
          widget.settings.copyWith(defaultAlertThreshold: threshold),
        );
  }

  void _setUnit(String u) {
    if (u == widget.settings.defaultUnit) return;
    context.read<SettingsProvider>().update(
          widget.settings.copyWith(defaultUnit: u),
        );
  }
}

// ────────────────────────────────────────────── Payment body ──

class _PaymentBody extends StatefulWidget {
  const _PaymentBody({required this.settings});
  final AppSettings settings;

  @override
  State<_PaymentBody> createState() => _PaymentBodyState();
}

class _PaymentBodyState extends State<_PaymentBody> {
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
    final methods = widget.settings.paymentMethods;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...AppConstants.paymentMethods.map((m) {
              final selected = methods.contains(m);
              return ShadowFilterChip(
                label: m[0].toUpperCase() + m.substring(1),
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
    );
  }

  void _toggleMethod(String method) {
    final current = widget.settings.paymentMethods;
    final updated = current.contains(method)
        ? current.where((m) => m != method).toList()
        : [...current, method];
    context.read<SettingsProvider>().update(
          widget.settings.copyWith(paymentMethods: updated),
        );
  }

  void _addCustom(String v) {
    final trimmed = v.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    final current = widget.settings.paymentMethods;
    if (current.contains(trimmed)) {
      _methodCtrl.clear();
      return;
    }
    context.read<SettingsProvider>().update(
          widget.settings.copyWith(paymentMethods: [...current, trimmed]),
        );
    _methodCtrl.clear();
  }
}

// ──────────────────────────────────────────────── Backup body ──

class _BackupBody extends StatelessWidget {
  const _BackupBody({
    required this.busy,
    required this.onBackup,
    required this.onRestore,
  });

  final bool busy;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          ShadowButton(
            label: 'Export Backup',
            icon: Icons.upload_file_rounded,
            expand: true,
            loading: busy,
            onPressed: busy ? null : onBackup,
          ),
          const SizedBox(height: 12),
          ShadowButton(
            label: 'Import Backup',
            icon: Icons.download_rounded,
            variant: ShadowButtonVariant.outline,
            expand: true,
            loading: busy,
            onPressed: busy ? null : onRestore,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────── ModeTile ──

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? ShadowColors.primary.withValues(alpha: 0.16)
                          : ShadowColors.muted,
                      border: Border.all(
                        color: selected
                            ? ShadowColors.primary.withValues(alpha: 0.5)
                            : ShadowColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? ShadowColors.primary
                          : ShadowColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: ShadowTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: ShadowTextStyles.bodyMuted.copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedScale(
                    scale: selected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 22,
                      color: ShadowColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: ShadowColors.border.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}
