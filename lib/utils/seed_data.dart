import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import 'app_constants.dart';

/// First-run seed + demo data. Written once by DatabaseHelper on database
/// creation (never re-run). All entities use freshly-minted UUIDs so
/// re-seeding a wiped DB produces different IDs.
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
      c('Food & Snacks', '🍕'),
      c('Health & Medicine', '💊'),
      c('Beauty & Cosmetics', '💄'),
      c('Sports & Fitness', '⚽'),
      c('Toys & Games', '🧸'),
      c('Automotive', '🚗'),
      c('Books & Media', '📚'),
      c('Pet Supplies', '🐾'),
      c('Baby & Kids', '👶'),
      c('Garden & Outdoor', '🌱'),
      c('Music & Instruments', '🎵'),
      c('Office Supplies', '🖥️'),
      c('Footwear', '👟'),
      c('Jewelry & Accessories', '💍'),
      c('Home Decor', '🛋️'),
      c('Tools & Hardware', '🔧'),
      c('Furniture', '🪑'),
      c('Party & Events', '🎉'),
      c('Travel & Luggage', '🧳'),
      c('Art & Craft', '🎨'),
      c('Frozen Foods', '❄️'),
      c('Dairy & Eggs', '🥛'),
      c('Meat & Seafood', '🥩'),
      c('Bakery', '🍞'),
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
        imagePath: '',
        createdAt: now,
        updatedAt: now,
      );
    }

    return [
      // Electronics
      p(name: 'Wireless Earbuds', buy: 45, sell: 79, stock: 24, emoji: '🎧', category: 'Electronics', brand: 'SoundPro'),
      p(name: 'Bluetooth Speaker', buy: 30, sell: 55, stock: 12, emoji: '🔊', category: 'Electronics', brand: 'BassKing'),
      p(name: 'USB-C Cable 1m', buy: 3, sell: 8, stock: 85, emoji: '🔌', category: 'Electronics', brand: 'QuickLink'),
      p(name: 'Power Bank 10000mAh', buy: 15, sell: 28, stock: 18, emoji: '🔋', category: 'Electronics', brand: 'JuiceBox'),
      p(name: 'Webcam HD 1080p', buy: 25, sell: 45, stock: 7, emoji: '📷', category: 'Electronics', brand: 'ClearView'),
      p(name: 'Mechanical Keyboard', buy: 55, sell: 95, stock: 9, emoji: '⌨️', category: 'Electronics', brand: 'ClickClack'),
      // Clothing
      p(name: 'Cotton T-Shirt', buy: 8, sell: 19, stock: 60, emoji: '👕', category: 'Clothing', brand: 'Basics'),
      p(name: 'Denim Jeans', buy: 20, sell: 45, stock: 35, emoji: '👖', category: 'Clothing', brand: 'UrbanFit'),
      p(name: 'Hoodie Black', buy: 22, sell: 49, stock: 20, emoji: '🧥', category: 'Clothing', brand: 'StreetWear'),
      p(name: 'Running Shoes', buy: 35, sell: 75, stock: 15, emoji: '👟', category: 'Footwear', brand: 'SprintMax'),
      // Grocery
      p(name: 'Coffee Beans 250g', buy: 6, sell: 12, stock: 3, emoji: '☕', category: 'Grocery', brand: 'RoastCo'),
      p(name: 'Olive Oil 500ml', buy: 8, sell: 16, stock: 22, emoji: '🫒', category: 'Grocery', brand: 'Mediterranean'),
      p(name: 'Pasta 500g', buy: 2, sell: 4.5, stock: 45, emoji: '🍝', category: 'Grocery', brand: 'Italiano'),
      p(name: 'Rice 1kg', buy: 3, sell: 6, stock: 50, emoji: '🍚', category: 'Grocery', brand: 'GoldenGrain'),
      // Beverages
      p(name: 'Sparkling Water', buy: 1, sell: 2.5, stock: 0, emoji: '🥤', category: 'Beverages', brand: 'Fresh'),
      p(name: 'Orange Juice 1L', buy: 2.5, sell: 5, stock: 28, emoji: '🍊', category: 'Beverages', brand: 'Sunny'),
      p(name: 'Energy Drink', buy: 1.5, sell: 3.5, stock: 40, emoji: '⚡', category: 'Beverages', brand: 'Volt'),
      // Household
      p(name: 'Dish Soap', buy: 2, sell: 4.5, stock: 18, emoji: '🧴', category: 'Household', brand: 'Clean+'),
      p(name: 'Laundry Detergent', buy: 5, sell: 10, stock: 14, emoji: '🧺', brand: 'FreshScent', category: 'Household'),
      p(name: 'Paper Towels 6pk', buy: 4, sell: 8, stock: 25, emoji: '🧻', category: 'Household', brand: 'AbsorbMax'),
      // Stationery
      p(name: 'Notebook A5', buy: 2, sell: 5, stock: 42, emoji: '📓', category: 'Stationery', brand: 'PaperCo'),
      p(name: 'Ballpoint Pen 10pk', buy: 3, sell: 7, stock: 55, emoji: '🖊️', category: 'Stationery', brand: 'WriteRight'),
      p(name: 'Sticky Notes 4pk', buy: 1.5, sell: 3.5, stock: 38, emoji: '📝', category: 'Stationery', brand: 'NoteUp'),
      // Health
      p(name: 'Vitamin C 60ct', buy: 5, sell: 12, stock: 30, emoji: '💊', category: 'Health & Medicine', brand: 'VitaLife'),
      p(name: 'Hand Sanitizer 250ml', buy: 2, sell: 5, stock: 22, emoji: '🧴', category: 'Health & Medicine', brand: 'PureGuard'),
      // Beauty
      p(name: 'Face Moisturizer', buy: 8, sell: 18, stock: 16, emoji: '💄', category: 'Beauty & Cosmetics', brand: 'GlowUp'),
      p(name: 'Shampoo 400ml', buy: 4, sell: 9, stock: 20, emoji: '🧴', category: 'Beauty & Cosmetics', brand: 'SilkHair'),
      // Sports
      p(name: 'Yoga Mat', buy: 10, sell: 25, stock: 12, emoji: '🧘', category: 'Sports & Fitness', brand: 'FlexFit'),
      p(name: 'Resistance Bands Set', buy: 6, sell: 15, stock: 18, emoji: '💪', category: 'Sports & Fitness', brand: 'PullForce'),
      // Food
      p(name: 'Protein Bars 12pk', buy: 12, sell: 24, stock: 10, emoji: '🍫', category: 'Food & Snacks', brand: 'FuelUp'),
      p(name: 'Mixed Nuts 300g', buy: 5, sell: 11, stock: 15, emoji: '🥜', category: 'Food & Snacks', brand: 'NutHouse'),
    ];
  }

  static List<Customer> customers(DateTime now) {
    Customer c(String name, String mobile, String email, {double balance = 0}) => Customer(
          id: _uuid.v4(),
          name: name,
          mobile: mobile,
          email: email,
          address: '',
          gstVat: '',
          notes: '',
          outstandingBalance: balance,
          createdAt: now,
          updatedAt: now,
        );
    return [
      c('Rahul Sharma', '+91 98765 43210', 'rahul@email.com', balance: 250),
      c('Priya Patel', '+91 87654 32109', 'priya@email.com'),
      c('Amit Singh', '+91 76543 21098', 'amit@email.com', balance: 120),
      c('Neha Gupta', '+91 65432 10987', 'neha@email.com'),
      c('Vikram Joshi', '+91 54321 09876', 'vikram@email.com', balance: 80),
      c('Sneha Reddy', '+91 43210 98765', 'sneha@email.com'),
      c('Arjun Nair', '+91 32109 87654', 'arjun@email.com', balance: 430),
      c('Kavita Desai', '+91 21098 76543', 'kavita@email.com'),
      c('Rohan Mehta', '+91 10987 65432', 'rohan@email.com', balance: 75),
      c('Ananya Iyer', '+91 09876 54321', 'ananya@email.com'),
      c('Deepak Verma', '+91 98712 34567', 'deepak@email.com', balance: 190),
      c('Pooja Kulkarni', '+91 87612 34568', 'pooja@email.com'),
    ];
  }

  static List<Supplier> suppliers(DateTime now) {
    Supplier s(String name, String contact, String mobile, String email, {double balance = 0}) => Supplier(
          id: _uuid.v4(),
          name: name,
          contactPerson: contact,
          mobile: mobile,
          email: email,
          address: '',
          gstVat: '',
          notes: '',
          outstandingBalance: balance,
          createdAt: now,
          updatedAt: now,
        );
    return [
      s('TechDistributors Inc.', 'Manish Kumar', '+91 98111 22233', 'manish@techdist.com', balance: 1500),
      s('FreshGoods Wholesale', 'Sunita Agarwal', '+91 98222 33344', 'sunita@freshgoods.com'),
      s('StyleHub Supplies', 'Rajesh Thakur', '+91 98333 44455', 'rajesh@stylehub.com', balance: 800),
      s('GreenLife Organics', 'Meera Chopra', '+91 98444 55566', 'meera@greenlife.com'),
      s('PowerUp Electronics', 'Suresh Pillai', '+91 98555 66677', 'suresh@powerup.com', balance: 2200),
    ];
  }

  static List<Transaction> transactions(List<Product> products, List<Customer> customers, List<Supplier> suppliers, DateTime now) {
    if (products.isEmpty || customers.isEmpty || suppliers.isEmpty) return [];

    Transaction txn({
      required TransactionType type,
      required double total,
      required double paid,
      required String entityName,
      required String entityId,
      required String payment,
      required List<TransactionItem> items,
      int daysAgo = 0,
    }) {
      final date = now.subtract(Duration(days: daysAgo, hours: now.hour, minutes: now.minute));
      return Transaction(
        id: _uuid.v4(),
        type: type,
        totalAmount: total,
        discount: 0,
        taxAmount: 0,
        notes: '',
        paymentMethod: payment,
        entityName: entityName,
        entityId: entityId,
        paidAmount: paid,
        createdAt: date,
        items: items,
      );
    }

    TransactionItem item({
      required String productId,
      required String productName,
      required String emoji,
      required int qty,
      required double price,
      required double cost,
    }) {
      return TransactionItem(
        id: _uuid.v4(),
        transactionId: '',
        productId: productId,
        productName: productName,
        productEmoji: emoji,
        productUnit: 'pcs',
        quantity: qty,
        priceAtTime: price,
        costPriceAtTime: cost,
        discount: 0,
        tax: 0,
        updatedAt: now,
      );
    }

    final p = products;
    final txns = <Transaction>[
      // Sales
      txn(
        type: TransactionType.sale,
        total: p[0].sellPrice * 2 + p[6].sellPrice * 3,
        paid: p[0].sellPrice * 2 + p[6].sellPrice * 3,
        entityName: customers[0].name,
        entityId: customers[0].id,
        payment: 'cash',
        daysAgo: 0,
        items: [
          item(productId: p[0].id, productName: p[0].name, emoji: p[0].emoji, qty: 2, price: p[0].sellPrice, cost: p[0].buyPrice),
          item(productId: p[6].id, productName: p[6].name, emoji: p[6].emoji, qty: 3, price: p[6].sellPrice, cost: p[6].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[10].sellPrice * 5,
        paid: p[10].sellPrice * 3,
        entityName: customers[1].name,
        entityId: customers[1].id,
        payment: 'card',
        daysAgo: 1,
        items: [
          item(productId: p[10].id, productName: p[10].name, emoji: p[10].emoji, qty: 5, price: p[10].sellPrice, cost: p[10].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[3].sellPrice + p[5].sellPrice,
        paid: p[3].sellPrice + p[5].sellPrice,
        entityName: customers[2].name,
        entityId: customers[2].id,
        payment: 'upi',
        daysAgo: 2,
        items: [
          item(productId: p[3].id, productName: p[3].name, emoji: p[3].emoji, qty: 1, price: p[3].sellPrice, cost: p[3].buyPrice),
          item(productId: p[5].id, productName: p[5].name, emoji: p[5].emoji, qty: 1, price: p[5].sellPrice, cost: p[5].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[17].sellPrice * 4 + p[18].sellPrice * 2,
        paid: p[17].sellPrice * 4 + p[18].sellPrice * 2,
        entityName: customers[3].name,
        entityId: customers[3].id,
        payment: 'cash',
        daysAgo: 3,
        items: [
          item(productId: p[17].id, productName: p[17].name, emoji: p[17].emoji, qty: 4, price: p[17].sellPrice, cost: p[17].buyPrice),
          item(productId: p[18].id, productName: p[18].name, emoji: p[18].emoji, qty: 2, price: p[18].sellPrice, cost: p[18].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[20].sellPrice * 10 + p[21].sellPrice * 5,
        paid: p[20].sellPrice * 10,
        entityName: customers[4].name,
        entityId: customers[4].id,
        payment: 'credit',
        daysAgo: 4,
        items: [
          item(productId: p[20].id, productName: p[20].name, emoji: p[20].emoji, qty: 10, price: p[20].sellPrice, cost: p[20].buyPrice),
          item(productId: p[21].id, productName: p[21].name, emoji: p[21].emoji, qty: 5, price: p[21].sellPrice, cost: p[21].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[23].sellPrice * 3 + p[24].sellPrice * 2,
        paid: p[23].sellPrice * 3 + p[24].sellPrice * 2,
        entityName: customers[5].name,
        entityId: customers[5].id,
        payment: 'card',
        daysAgo: 5,
        items: [
          item(productId: p[23].id, productName: p[23].name, emoji: p[23].emoji, qty: 3, price: p[23].sellPrice, cost: p[23].buyPrice),
          item(productId: p[24].id, productName: p[24].name, emoji: p[24].emoji, qty: 2, price: p[24].sellPrice, cost: p[24].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[8].sellPrice * 2 + p[9].sellPrice,
        paid: p[8].sellPrice * 2 + p[9].sellPrice,
        entityName: customers[6].name,
        entityId: customers[6].id,
        payment: 'upi',
        daysAgo: 6,
        items: [
          item(productId: p[8].id, productName: p[8].name, emoji: p[8].emoji, qty: 2, price: p[8].sellPrice, cost: p[8].buyPrice),
          item(productId: p[9].id, productName: p[9].name, emoji: p[9].emoji, qty: 1, price: p[9].sellPrice, cost: p[9].buyPrice),
        ],
      ),
      // Purchases
      txn(
        type: TransactionType.purchase,
        total: p[0].buyPrice * 50 + p[3].buyPrice * 30,
        paid: p[0].buyPrice * 50 + p[3].buyPrice * 30,
        entityName: suppliers[0].name,
        entityId: suppliers[0].id,
        payment: 'bank',
        daysAgo: 7,
        items: [
          item(productId: p[0].id, productName: p[0].name, emoji: p[0].emoji, qty: 50, price: p[0].sellPrice, cost: p[0].buyPrice),
          item(productId: p[3].id, productName: p[3].name, emoji: p[3].emoji, qty: 30, price: p[3].sellPrice, cost: p[3].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.purchase,
        total: p[10].buyPrice * 100 + p[11].buyPrice * 60,
        paid: p[10].buyPrice * 100,
        entityName: suppliers[1].name,
        entityId: suppliers[1].id,
        payment: 'credit',
        daysAgo: 10,
        items: [
          item(productId: p[10].id, productName: p[10].name, emoji: p[10].emoji, qty: 100, price: p[10].sellPrice, cost: p[10].buyPrice),
          item(productId: p[11].id, productName: p[11].name, emoji: p[11].emoji, qty: 60, price: p[11].sellPrice, cost: p[11].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.purchase,
        total: p[6].buyPrice * 200 + p[7].buyPrice * 100,
        paid: p[6].buyPrice * 200 + p[7].buyPrice * 100,
        entityName: suppliers[2].name,
        entityId: suppliers[2].id,
        payment: 'bank',
        daysAgo: 12,
        items: [
          item(productId: p[6].id, productName: p[6].name, emoji: p[6].emoji, qty: 200, price: p[6].sellPrice, cost: p[6].buyPrice),
          item(productId: p[7].id, productName: p[7].name, emoji: p[7].emoji, qty: 100, price: p[7].sellPrice, cost: p[7].buyPrice),
        ],
      ),
      // More sales for variety
      txn(
        type: TransactionType.sale,
        total: p[25].sellPrice * 2 + p[26].sellPrice,
        paid: p[25].sellPrice * 2 + p[26].sellPrice,
        entityName: customers[7].name,
        entityId: customers[7].id,
        payment: 'cash',
        daysAgo: 1,
        items: [
          item(productId: p[25].id, productName: p[25].name, emoji: p[25].emoji, qty: 2, price: p[25].sellPrice, cost: p[25].buyPrice),
          item(productId: p[26].id, productName: p[26].name, emoji: p[26].emoji, qty: 1, price: p[26].sellPrice, cost: p[26].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[27].sellPrice * 3 + p[28].sellPrice * 2,
        paid: p[27].sellPrice * 3 + p[28].sellPrice * 2,
        entityName: customers[8].name,
        entityId: customers[8].id,
        payment: 'card',
        daysAgo: 2,
        items: [
          item(productId: p[27].id, productName: p[27].name, emoji: p[27].emoji, qty: 3, price: p[27].sellPrice, cost: p[27].buyPrice),
          item(productId: p[28].id, productName: p[28].name, emoji: p[28].emoji, qty: 2, price: p[28].sellPrice, cost: p[28].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[29].sellPrice * 4 + p[30].sellPrice * 3,
        paid: p[29].sellPrice * 2,
        entityName: customers[9].name,
        entityId: customers[9].id,
        payment: 'credit',
        daysAgo: 3,
        items: [
          item(productId: p[29].id, productName: p[29].name, emoji: p[29].emoji, qty: 4, price: p[29].sellPrice, cost: p[29].buyPrice),
          item(productId: p[30].id, productName: p[30].name, emoji: p[30].emoji, qty: 3, price: p[30].sellPrice, cost: p[30].buyPrice),
        ],
      ),
      txn(
        type: TransactionType.sale,
        total: p[1].sellPrice * 2 + p[2].sellPrice * 10,
        paid: p[1].sellPrice * 2 + p[2].sellPrice * 10,
        entityName: customers[10].name,
        entityId: customers[10].id,
        payment: 'upi',
        daysAgo: 4,
        items: [
          item(productId: p[1].id, productName: p[1].name, emoji: p[1].emoji, qty: 2, price: p[1].sellPrice, cost: p[1].buyPrice),
          item(productId: p[2].id, productName: p[2].name, emoji: p[2].emoji, qty: 10, price: p[2].sellPrice, cost: p[2].buyPrice),
        ],
      ),
    ];

    // Stamp transaction IDs onto items
    final stamped = <Transaction>[];
    for (final t in txns) {
      final items = t.items.map((i) => TransactionItem(
        id: i.id,
        transactionId: t.id,
        productId: i.productId,
        productName: i.productName,
        productEmoji: i.productEmoji,
        productUnit: i.productUnit,
        quantity: i.quantity,
        priceAtTime: i.priceAtTime,
        costPriceAtTime: i.costPriceAtTime,
        discount: i.discount,
        tax: i.tax,
        updatedAt: i.updatedAt,
      )).toList();
      stamped.add(t.copyWith(items: items));
    }
    return stamped;
  }
}
