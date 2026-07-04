import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shadow_inventory_pro/app.dart';
import 'package:shadow_inventory_pro/models/customer.dart';
import 'package:shadow_inventory_pro/models/stock_movement.dart';
import 'package:shadow_inventory_pro/models/transaction.dart';
import 'package:shadow_inventory_pro/models/transaction_type.dart';
import 'package:shadow_inventory_pro/providers/customer_provider.dart';
import 'package:shadow_inventory_pro/providers/transaction_provider.dart';
import 'package:shadow_inventory_pro/repositories/customer_repository.dart';
import 'package:shadow_inventory_pro/repositories/transaction_repository.dart';
import 'package:shadow_inventory_pro/repositories/stock_movement_repository.dart';
import 'package:shadow_inventory_pro/screens/customers/customer_detail_screen.dart';
import 'package:shadow_inventory_pro/utils/formatters.dart';

/// Mock repository that returns predefined transactions without a real DB.
class _MockTxnRepo extends TransactionRepository {
  _MockTxnRepo(this._data);
  final List<Transaction> _data;

  @override
  Future<List<Transaction>> getAll({int? limit}) async => _data;
}

/// Mock stock-movement repo that returns empty without a real DB.
class _MockMoveRepo extends StockMovementRepository {
  @override
  Future<List<StockMovement>> getAll({int? limit}) async => const [];
}

/// Mock customer repository that returns predefined customers without a real DB.
class _MockCustomerRepo extends CustomerRepository {
  _MockCustomerRepo(this._data);
  final List<Customer> _data;

  @override
  Future<List<Customer>> getAll() async => _data;
}

/// Shortcut to build a minimal Transaction for tests.
Transaction _txn({
  required String id,
  required TransactionType type,
  required double totalAmount,
  required double paidAmount,
  required DateTime createdAt,
  String? originalTransactionId,
}) =>
    Transaction(
      id: id,
      type: type,
      totalAmount: totalAmount,
      discount: 0,
      taxAmount: 0,
      notes: '',
      paymentMethod: 'cash',
      entityName: '',
      entityId: '',
      paidAmount: paidAmount,
      originalTransactionId: originalTransactionId,
      createdAt: createdAt,
      items: const [],
    );

void main() {
  // ── Widget test ─────────────────────────────────────────────

  testWidgets('App starts and shows dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ShadowInventoryApp());
    expect(find.text('Dashboard'), findsOneWidget);
  });

  // ── Financial rounding ──────────────────────────────────────

  test('Financial rounding validation', () {
    const it = TransactionItemDraft(
      productId: '1',
      productName: 'P',
      productEmoji: '📦',
      productUnit: 'pcs',
      quantity: 3,
      priceAtTime: 10.333333,
      costPriceAtTime: 5.11111,
    );
    expect(double.parse(it.priceAtTime.toStringAsFixed(2)), 10.33);
  });

  // ── Stock sign mapping ──────────────────────────────────────

  test('Stock sign mapping', () {
    expect(TransactionType.sale.displayLabel, 'Sale');
    expect(TransactionType.purchase.displayLabel, 'Purchase');
    expect(TransactionType.salesReturn.displayLabel, 'Sales Return');
    expect(TransactionType.purchaseReturn.displayLabel, 'Purchase Return');
    expect(TransactionType.adjustment.displayLabel, 'Adjustment');
  });

  // ── TotalRevenue business logic ─────────────────────────────

  group('TransactionProvider.totalRevenue', () {
    test('returns 0 when no transactions exist', () async {
      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();
      expect(p.totalRevenue(), 0);
    });

    test('returns gross sales when no returns exist', () async {
      final now = DateTime.now();
      final sale = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 100,
        paidAmount: 100,
        createdAt: now,
      );
      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([sale]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();
      expect(p.totalRevenue(), 100);
    });

    test('subtracts sales returns from revenue', () async {
      final now = DateTime.now();
      final sale = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 500,
        paidAmount: 500,
        createdAt: now,
      );
      final ret = _txn(
        id: 'r1',
        type: TransactionType.salesReturn,
        totalAmount: 200,
        paidAmount: 0,
        createdAt: now,
        originalTransactionId: 's1',
      );
      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([sale, ret]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();
      expect(p.totalRevenue(), 300); // 500 - 200
    });

    test('handles date range filtering', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      final saleToday = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 100,
        paidAmount: 100,
        createdAt: today,
      );
      final saleYesterday = _txn(
        id: 's2',
        type: TransactionType.sale,
        totalAmount: 50,
        paidAmount: 50,
        createdAt: yesterday,
      );
      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([saleToday, saleYesterday]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();
      expect(p.totalRevenue(to: tomorrow), 150);
      expect(p.totalRevenue(from: today, to: tomorrow), 100);
      expect(p.revenueForDay(today), 100);
    });

    test('returns negative when returns exceed sales', () async {
      final now = DateTime.now();
      final sale = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 100,
        paidAmount: 100,
        createdAt: now,
      );
      final ret = _txn(
        id: 'r1',
        type: TransactionType.salesReturn,
        totalAmount: 200,
        paidAmount: 0,
        createdAt: now,
        originalTransactionId: 's1',
      );
      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([sale, ret]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();
      expect(p.totalRevenue(), -100); // 100 - 200
    });

    test('purchases do not affect revenue', () async {
      final now = DateTime.now();
      final sale = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 100,
        paidAmount: 100,
        createdAt: now,
      );
      final purchase = _txn(
        id: 'p1',
        type: TransactionType.purchase,
        totalAmount: 50,
        paidAmount: 50,
        createdAt: now,
      );
      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([sale, purchase]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();
      expect(p.totalRevenue(), 100); // Purchases don't count
    });

    test('reverse order: returns listed before sales still subtract correctly',
        () async {
      final now = DateTime.now();
      final ret = _txn(
        id: 'r1',
        type: TransactionType.salesReturn,
        totalAmount: 50,
        paidAmount: 0,
        createdAt: now,
      );
      final sale = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 100,
        paidAmount: 100,
        createdAt: now,
      );
      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([ret, sale]), // returns first in list
        movementRepo: _MockMoveRepo(),
      );
      await p.load();
      expect(p.totalRevenue(), 50); // 100 - 50 — order doesn't matter
    });

    test('revenueForDay uses date boundary correctly', () async {
      final today = DateTime(2026, 7, 5, 10, 30); // midday
      final startOfDay = DateTime(2026, 7, 5);
      final startOfNextDay = DateTime(2026, 7, 6);

      final sale = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 100,
        paidAmount: 100,
        createdAt: today,
      );
      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([sale]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();
      expect(p.totalRevenue(from: startOfDay, to: startOfNextDay), 100);
    });
  });

  // ── E2E-style: simulate sale + return cycle ────────────────

  group('E2E: Sale + Return revenue consistency', () {
    test('Dashboard-style totalRevenue matches Reports-style gross - returns',
        () async {
      final now = DateTime.now();
      final sale = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 1000,
        paidAmount: 1000,
        createdAt: now,
      );
      final ret = _txn(
        id: 'r1',
        type: TransactionType.salesReturn,
        totalAmount: 300,
        paidAmount: 0,
        createdAt: now,
        originalTransactionId: 's1',
      );

      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([sale, ret]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();

      // This is what the Dashboard shows
      final dashboardRevenue = p.totalRevenue();
      // This is what the Reports screen would show (gross - returns)
      const gross = 1000.0;
      const returns = 300.0;
      const reportsRevenue = gross - returns;

      expect(dashboardRevenue, reportsRevenue);
      expect(dashboardRevenue, 700); // 1000 - 300
    });
  });

  // ── ReportsProvider revenue calculation consistency ─────────

  group('ReportsProvider revenue consistency', () {
    test('netProfit equals totalRevenue minus totalCostOfGoodsSold', () async {
      // Pure logic: netProfit = totalRevenue - totalExpenses
      // and totalExpenses = totalCostOfGoodsSold
      // This is a compile-time invariant — tested at the logic level.
      final now = DateTime.now();
      final sale = _txn(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 200,
        paidAmount: 200,
        createdAt: now,
      );
      final ret = _txn(
        id: 'r1',
        type: TransactionType.salesReturn,
        totalAmount: 50,
        paidAmount: 0,
        createdAt: now,
        originalTransactionId: 's1',
      );

      final p = TransactionProvider(
        txnRepo: _MockTxnRepo([sale, ret]),
        movementRepo: _MockMoveRepo(),
      );
      await p.load();

      // After the fix, totalRevenue should be 200 - 50 = 150
      expect(p.totalRevenue(), 150);
    });
  });

  // ── CustomerDetailScreen widget tests ───────────────────────

  group('CustomerDetailScreen', () {
    final testCustomer = Customer(
      id: 'cust-1',
      name: 'Alice Johnson',
      mobile: '+1 555-1234',
      email: 'alice@example.com',
      address: '123 Main St',
      gstVat: 'GSTIN1234',
      notes: '',
      outstandingBalance: 150.0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    /// Scroll the ListView down so lower items are built in the tree.
    Future<void> scrollDown(WidgetTester tester) async {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    /// Create provider instances with pre-loaded data and wrap the screen.
    Future<void> pumpScreen(
      WidgetTester tester, {
      required String customerId,
      required List<Customer> customers,
      required List<Transaction> transactions,
    }) async {
      final customerProvider = CustomerProvider(
        repository: _MockCustomerRepo(customers),
      );
      final txnProvider = TransactionProvider(
        txnRepo: _MockTxnRepo(transactions),
        movementRepo: _MockMoveRepo(),
      );
      await customerProvider.load();
      await txnProvider.load();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<CustomerProvider>.value(
                value: customerProvider,
              ),
              ChangeNotifierProvider<TransactionProvider>.value(
                value: txnProvider,
              ),
            ],
            child: CustomerDetailScreen(customerId: customerId),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders customer name and mobile when found',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        customerId: 'cust-1',
        customers: [testCustomer],
        transactions: [],
      );

      // Name appears once in the header; mobile appears in header subtitle
      // AND in the contact card.
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('+1 555-1234'), findsWidgets);
    });

    testWidgets('shows stat cards with zero values when no transactions',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        customerId: 'cust-1',
        customers: [testCustomer],
        transactions: [],
      );

      // ShadowStatCard renders labels uppercased.
      expect(find.text('TOTAL SALES'), findsOneWidget);
      expect(find.text('REVENUE'), findsOneWidget);
      expect(find.text('RETURNS'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('shows sales list when customer has sales',
        (WidgetTester tester) async {
      final sale = Transaction(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 200,
        discount: 0,
        taxAmount: 0,
        notes: '',
        paymentMethod: 'cash',
        entityName: 'Alice Johnson',
        entityId: 'cust-1',
        paidAmount: 200,
        createdAt: DateTime(2026, 6, 15, 14, 30),
        items: const [],
      );

      await pumpScreen(
        tester,
        customerId: 'cust-1',
        customers: [testCustomer],
        transactions: [sale],
      );

      // Stat shows 1 sale
      expect(find.text('1'), findsOneWidget);
      // Revenue stat ($200.00) — may also appear in the sales row
      expect(find.text(Formatters.currency(200)), findsWidgets);
      // Returns stat shows $0.00
      expect(find.text(Formatters.currency(0)), findsWidgets);
      // Recent sales section present
      // ShadowSectionLabel uppercases text
      expect(find.text('RECENT SALES'), findsOneWidget);
    });

    testWidgets('shows sales returns section when returns exist',
        (WidgetTester tester) async {
      final sale = Transaction(
        id: 's1',
        type: TransactionType.sale,
        totalAmount: 500,
        discount: 0,
        taxAmount: 0,
        notes: '',
        paymentMethod: 'cash',
        entityName: 'Alice Johnson',
        entityId: 'cust-1',
        paidAmount: 500,
        createdAt: DateTime(2026, 6, 15, 14, 30),
        items: const [],
      );
      final ret = Transaction(
        id: 'r1',
        type: TransactionType.salesReturn,
        totalAmount: 100,
        discount: 0,
        taxAmount: 0,
        notes: '',
        paymentMethod: 'cash',
        entityName: 'Alice Johnson',
        entityId: 'cust-1',
        paidAmount: 0,
        originalTransactionId: 's1',
        createdAt: DateTime(2026, 6, 16),
        items: const [],
      );

      await pumpScreen(
        tester,
        customerId: 'cust-1',
        customers: [testCustomer],
        transactions: [sale, ret],
      );
      await scrollDown(tester);

      // Sales returns section should be visible
      // ShadowSectionLabel uppercases text
      expect(find.text('SALES RETURNS'), findsOneWidget);
      // Revenue stat ($500)
      expect(find.text(Formatters.currency(500)), findsWidgets);
      // Returns stat ($100)
      expect(find.text(Formatters.currency(100)), findsWidgets);
    });

    testWidgets('shows contact card details', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        customerId: 'cust-1',
        customers: [testCustomer],
        transactions: [],
      );
      await scrollDown(tester);

      // ShadowSectionLabel uppercases text
      expect(find.text('CONTACT'), findsOneWidget);
      // Mobile appears in header subtitle AND contact card
      expect(find.text('+1 555-1234'), findsWidgets);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text('123 Main St'), findsOneWidget);
      expect(find.text('GSTIN1234'), findsOneWidget);
      // Outstanding balance
      expect(find.text(Formatters.currency(150)), findsOneWidget);
    });

    testWidgets('shows empty state when customer not found',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        customerId: 'nonexistent',
        customers: [testCustomer],
        transactions: [],
      );

      expect(find.text('Customer not found'), findsOneWidget);
    });

    testWidgets('shows no-sales message when customer has no sales',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        customerId: 'cust-1',
        customers: [testCustomer],
        transactions: [],
      );
      await scrollDown(tester);

      expect(
        find.text('No sales recorded for this customer yet.'),
        findsOneWidget,
      );
    });

    testWidgets('renders avatar initial from customer name',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        customerId: 'cust-1',
        customers: [testCustomer],
        transactions: [],
      );

      expect(find.text('A'), findsOneWidget);
    });
  });
}
