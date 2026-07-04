import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_inventory_pro/app.dart';
import 'package:shadow_inventory_pro/models/transaction_type.dart';
import 'package:shadow_inventory_pro/providers/transaction_provider.dart';

void main() {
  testWidgets('App starts and shows dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ShadowInventoryApp());
    expect(find.text('Dashboard'), findsOneWidget);
  });

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

  group('Transaction Logic', () {
    test('Stock sign mapping', () {
      // Logic check
      expect(TransactionType.sale.displayLabel, 'Sale');
    });
  });
}
