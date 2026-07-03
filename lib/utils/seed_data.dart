import 'package:uuid/uuid.dart';

import '../models/product.dart';
import 'app_constants.dart';

/// Initial products copied from the original Shadow HTML application.
abstract final class SeedData {
  const SeedData._();

  static const Uuid _uuid = Uuid();

  /// Returns a fresh set of seed products.
  static List<Product> initialProducts() {
    final DateTime now = DateTime.now();

    return <Product>[
      _product(
        name: 'Sony WH-1000XM5',
        buyPrice: 280,
        sellPrice: 380,
        stock: 24,
        emoji: '🎧',
        now: now,
      ),
      _product(
        name: 'iPhone 15 Pro Case',
        buyPrice: 8,
        sellPrice: 25,
        stock: 3,
        emoji: '📱',
        now: now,
      ),
      _product(
        name: 'USB-C Hub 7-in-1',
        buyPrice: 22,
        sellPrice: 55,
        stock: 0,
        emoji: '🔌',
        now: now,
      ),
      _product(
        name: 'Mechanical Keyboard',
        buyPrice: 65,
        sellPrice: 120,
        stock: 7,
        emoji: '⌨️',
        now: now,
      ),
      _product(
        name: 'Wireless Charger Pad',
        buyPrice: 12,
        sellPrice: 30,
        stock: 18,
        emoji: '⚡',
        now: now,
      ),
    ];
  }

  static Product _product({
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int stock,
    required String emoji,
    required DateTime now,
  }) {
    return Product(
      id: _uuid.v4(),
      name: name,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      stock: stock,
      alertThreshold: AppConstants.defaultLowStockAlert,
      imagePath: null,
      emoji: emoji,
      createdAt: now,
      updatedAt: now,
    );
  }
}
