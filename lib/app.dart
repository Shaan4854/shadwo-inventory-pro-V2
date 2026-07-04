import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/category_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/shell/app_shell.dart';
import 'theme/app_theme.dart';

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
      context.read<CategoryProvider>().load();
      context.read<CustomerProvider>().load();
      context.read<SupplierProvider>().load();
      context.read<TransactionProvider>().load();
      context.read<ReportsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
