import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/shell/app_shell.dart';
import 'theme/app_theme.dart';

/// Root of the app. Owns the `MultiProvider` tree — each provider is a
/// singleton for the app lifetime and `load()`s once on first build via
/// `_ProviderBootstrap`.
class ShadowInventoryApp extends StatelessWidget {
  const ShadowInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'Shadow Inventory Pro',
        debugShowCheckedModeBanner: false,
        theme: ShadowTheme.dark(),
        darkTheme: ShadowTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const _ProviderBootstrap(child: AppShell()),
      ),
    );
  }
}

/// Fires the initial `load()` on all four providers exactly once, then
/// hands off to the wrapped child. Cheaper than doing per-screen loading
/// in every screen's initState, and keeps the ordering deterministic.
class _ProviderBootstrap extends StatefulWidget {
  const _ProviderBootstrap({required this.child});

  final Widget child;

  @override
  State<_ProviderBootstrap> createState() => _ProviderBootstrapState();
}

class _ProviderBootstrapState extends State<_ProviderBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().load();
      context.read<CustomerProvider>().load();
      context.read<SupplierProvider>().load();
      context.read<TransactionProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
