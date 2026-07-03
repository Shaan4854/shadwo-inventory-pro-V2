import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/product.dart';
import 'app_constants.dart';

/// First-run seed. Written once by DatabaseHelper on database creation
/// (never re-run). All entities use freshly-minted UUIDs so re-seeding a
/// wiped DB produces different IDs — that's fine, nothing external
/// references them.
class SeedData {
  SeedData._();

  static const _uuid = Uuid();

  static List<Category> categories(DateTime now) {
    Category c(String name, String emoji) => Category(
          id: _uuid.v4(),
          name: name,
          emoji: emoji,
          createdAt: now,
        );
    return [
      c('Electronics', '📱'),
      c('Clothing', '👕'),
      c('Grocery', '🛒'),
      c('Beverages', '🥤'),
      c('Stationery', '📎'),
      c('Household', '🧽'),
    ];
  }

  static List<Product> products(DateTime now) {
    Product p({
      required String name,
      required double buy,
      required double sell,
      required int stock,
      required String emoji,
      required String category,
      required String brand,
    }) {
      return Product(
        id: _uuid.v4(),
        name: name,
        buyPrice: buy,
        sellPrice: sell,
        stock: stock,
        alertThreshold: AppConstants.defaultAlertThreshold,
        emoji: emoji,
        category: category,
        brand: brand,
        unit: AppConstants.defaultUnit,
        sku: '',
        barcode: '',
        notes: '',
        createdAt: now,
        updatedAt: now,
      );
    }

    return [
      p(
        name: 'Wireless Earbuds',
        buy: 45,
        sell: 79,
        stock: 24,
        emoji: '🎧',
        category: 'Electronics',
        brand: 'SoundPro',
      ),
      p(
        name: 'Cotton T-Shirt',
        buy: 8,
        sell: 19,
        stock: 60,
        emoji: '👕',
        category: 'Clothing',
        brand: 'Basics',
      ),
      p(
        name: 'Coffee Beans 250g',
        buy: 6,
        sell: 12,
        stock: 3,
        emoji: '☕',
        category: 'Grocery',
        brand: 'RoastCo',
      ),
      p(
        name: 'Sparkling Water',
        buy: 1,
        sell: 2.5,
        stock: 0,
        emoji: '🥤',
        category: 'Beverages',
        brand: 'Fresh',
      ),
      p(
        name: 'Notebook A5',
        buy: 2,
        sell: 5,
        stock: 42,
        emoji: '📓',
        category: 'Stationery',
        brand: 'PaperCo',
      ),
      p(
        name: 'Dish Soap',
        buy: 2,
        sell: 4.5,
        stock: 18,
        emoji: '🧴',
        category: 'Household',
        brand: 'Clean+',
      ),
    ];
  }
}
