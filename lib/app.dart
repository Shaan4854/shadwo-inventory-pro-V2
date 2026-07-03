import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/supplier_provider.dart';
import 'repositories/sqlite_customer_repository.dart';
import 'repositories/sqlite_product_repository.dart';
import 'repositories/sqlite_supplier_repository.dart';
import 'screens/shell/app_shell.dart';
import 'theme/app_theme.dart';

/// Root widget: wires the locked provider/repository stack (copied
/// as-is from `main`) and the v2 theme, then hands off to
/// [ShadowAppShell] for navigation.
class ShadowInventoryProApp extends StatelessWidget {
  const ShadowInventoryProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(
            productRepository: SQLiteProductRepository(),
          )..loadProducts(),
        ),
        ChangeNotifierProvider<CustomerProvider>(
          create: (_) => CustomerProvider(
            customerRepository: SQLiteCustomerRepository(),
          )..loadCustomers(),
        ),
        ChangeNotifierProvider<SupplierProvider>(
          create: (_) => SupplierProvider(
            supplierRepository: SQLiteSupplierRepository(),
          )..loadSuppliers(),
        ),
        ChangeNotifierProxyProvider3<ProductProvider, CustomerProvider,
            SupplierProvider, ReportsProvider>(
          create: (BuildContext context) => ReportsProvider(
            productProvider: context.read<ProductProvider>(),
            customerProvider: context.read<CustomerProvider>(),
            supplierProvider: context.read<SupplierProvider>(),
          ),
          update: (
            BuildContext context,
            ProductProvider productProvider,
            CustomerProvider customerProvider,
            SupplierProvider supplierProvider,
            ReportsProvider? previous,
          ) =>
              ReportsProvider(
            productProvider: productProvider,
            customerProvider: customerProvider,
            supplierProvider: supplierProvider,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Shadow Inventory Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ShadowAppShell(),
      ),
    );
  }
}
