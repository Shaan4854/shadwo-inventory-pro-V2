import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/category_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/shell/app_shell.dart';
import 'theme/theme_controller.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().load();
      context.read<CategoryProvider>().load();
      context.read<CustomerProvider>().load();
      context.read<SupplierProvider>().load();
      context.read<TransactionProvider>().load();
      context.read<ReportsProvider>().load();
    });
  }

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
        child: AppShell(tab: _tab),
      ),
    );
  }
}
