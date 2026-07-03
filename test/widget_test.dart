// Basic smoke test — no per-screen widget tests exist yet.
// Verifies the app's root widget builds without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:shadow_inventory_pro/app.dart';

void main() {
  testWidgets('ShadowInventoryProApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ShadowInventoryProApp());
    await tester.pump();

    expect(find.byType(ShadowInventoryProApp), findsOneWidget);
  });
}
