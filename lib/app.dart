import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/category_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/shell/app_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'theme/theme_controller.dart';
import 'utils/backup_service.dart';
import 'utils/first_launch_helper.dart';
import 'widgets/ui_kit/ui_kit.dart';

class ShadowInventoryApp extends StatelessWidget {
  const ShadowInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
      ],
      child: const _AppRoot(),
    );
  }
}

/// Hosts the [MaterialApp] and reacts to theme changes.
///
/// The themed body is remounted (via a brightness-keyed subtree) whenever
/// the effective brightness flips, so every widget re-reads the active
/// [ShadowColors] palette — even `const` subtrees that Flutter would
/// otherwise skip rebuilding. The selected tab is lifted into [_tab] so it
/// survives that remount instead of snapping back to Home.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final ValueNotifier<int> _tab = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return MaterialApp(
      title: 'Shadow Inventory Pro',
      debugShowCheckedModeBanner: false,
      theme: controller.themeData,
      home: KeyedSubtree(
        key: ValueKey<Brightness>(controller.effectiveBrightness),
        child: _WelcomeGate(tab: _tab),
      ),
    );
  }
}

/// Renders [AppShell] once the first-launch welcome check is done.
/// Lives inside [MaterialApp] so [showDialog] has MaterialLocalizations.
class _WelcomeGate extends StatefulWidget {
  const _WelcomeGate({required this.tab});
  final ValueNotifier<int> tab;

  @override
  State<_WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<_WelcomeGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _check();
    });
  }

  Future<void> _check() async {
    final pp = context.read<ProductProvider>();
    final cp = context.read<CategoryProvider>();
    final cust = context.read<CustomerProvider>();
    final sp = context.read<SupplierProvider>();
    final tp = context.read<TransactionProvider>();
    final rp = context.read<ReportsProvider>();

    await Future.wait([
      pp.load(),
      cp.load(),
      cust.load(),
      sp.load(),
      tp.load(),
      rp.load(),
    ]);
    if (!mounted) return;

    if (await FirstLaunchHelper.isWelcomeShown()) {
      if (!mounted) return;
      setState(() => _ready = true);
      return;
    }

    if (pp.all.isNotEmpty || tp.all.isNotEmpty) {
      if (!mounted) return;
      setState(() => _ready = true);
      return;
    }

    final action = await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Welcome to Shadow Inventory Pro',
            style: ShadowTextStyles.h4),
        content: Text(
          'Restore from a previous backup, or start fresh?',
          style: ShadowTextStyles.body,
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          ShadowButton(
            label: 'Start Fresh',
            variant: ShadowButtonVariant.ghost,
            size: ShadowButtonSize.sm,
            onPressed: () => Navigator.pop(ctx, 'fresh'),
          ),
          ShadowButton(
            label: 'Restore from Backup',
            variant: ShadowButtonVariant.primary,
            size: ShadowButtonSize.sm,
            onPressed: () => Navigator.pop(ctx, 'restore'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (action == 'restore') {
      final path = await BackupService.pickFile();
      if (path != null && mounted) {
        final confirmed = await ShadowConfirmDialog.show(
          // ignore: use_build_context_synchronously
          context,
          title: 'Restore Backup?',
          message: 'This will replace ALL current data with the backup. '
              'This action cannot be undone.',
          confirmLabel: 'Restore',
          danger: true,
        );
        if (confirmed && mounted) {
          final ok = await BackupService.restore(path);
          if (ok && mounted) {
            await Future.wait([
              pp.load(),
              cp.load(),
              cust.load(),
              sp.load(),
              tp.load(),
              rp.load(),
            ]);
          }
        }
      }
    }

    if (!mounted) return;
    await FirstLaunchHelper.markWelcomeShown();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.shrink();
    }
    return AppShell(tab: widget.tab);
  }
}
