import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../utils/app_constants.dart';
import '../utils/seed_data.dart';

/// Singleton wrapper around the app's sqflite database. Every repository
/// obtains its Database via wait DatabaseHelper.instance.database.
///
/// Schema is versioned; onUpgrade handles forward migrations. NEVER
/// downgrade — spec-locked at v15.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  Future<void>? _openFuture;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _openFuture ??= _open().then((db) {
      _db = db;
      return db;
    }).catchError((Object e) {
      _openFuture = null;
      throw e;
    });
    await _openFuture;
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    _createProducts(batch);
    _createCategories(batch);
    _createCustomers(batch);
    _createSuppliers(batch);
    _createTransactions(batch);
    _createTransactionItems(batch);
    _createStockMovements(batch);
    _createProductVariants(batch);
    _createAppSettings(batch);
    _createIndexes(batch);
    await batch.commit(noResult: true);
    await _seedDefaults(db);
    await _seedIfEmpty(db, categoriesOnly: true);
  }

  Future<void> _seedDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('app_settings', {
      'id': 1,
      'currency_symbol': '\$',
      'currency_position': 'left',
      'date_format': 'dd MMM yyyy',
      'default_alert_threshold': 5,
      'default_unit': 'pcs',
      'payment_methods': 'cash,card,credit',
      'barcode_lookup_url': 'http://localhost:8000',
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 8) {
      final batch = db.batch();
      _dropAll(batch);
      _createProducts(batch);
      _createCategories(batch);
      _createCustomers(batch);
      _createSuppliers(batch);
      _createTransactions(batch);
      _createTransactionItems(batch);
      _createStockMovements(batch);
      _createProductVariants(batch);
      _createAppSettings(batch);
      _createIndexes(batch);
      await batch.commit(noResult: true);
    }
    
    if (oldV < 11) {
      final columns = await db.rawQuery('PRAGMA table_info(transactions)');
      final hasColumn = columns.any((c) => c['name'] == 'original_transaction_id');
      if (!hasColumn) {
        await db.execute('ALTER TABLE transactions ADD COLUMN original_transaction_id TEXT');
      }
    }

    if (oldV < 12) {
      final columns = await db.rawQuery('PRAGMA table_info(products)');
      final hasColumn = columns.any((c) => c['name'] == 'image_path');
      if (!hasColumn) {
        await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT NOT NULL DEFAULT ""');
      }
    }

    if (oldV < 13) {
      final itemColumns =
          await db.rawQuery('PRAGMA table_info(transaction_items)');
      if (!itemColumns.any((c) => c['name'] == 'product_image_path')) {
        await db.execute(
            'ALTER TABLE transaction_items ADD COLUMN product_image_path TEXT NOT NULL DEFAULT ""');
      }
      final movementColumns =
          await db.rawQuery('PRAGMA table_info(stock_movements)');
      if (!movementColumns.any((c) => c['name'] == 'product_image_path')) {
        await db.execute(
            'ALTER TABLE stock_movements ADD COLUMN product_image_path TEXT NOT NULL DEFAULT ""');
      }
    }

    if (oldV < 14) {
      final columns = await db.rawQuery('PRAGMA table_info(app_settings)');
      if (!columns.any((c) => c['name'] == 'id')) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            id                     INTEGER PRIMARY KEY DEFAULT 1,
            currency_symbol        TEXT NOT NULL DEFAULT '\$',
            currency_position      TEXT NOT NULL DEFAULT 'left',
            date_format            TEXT NOT NULL DEFAULT 'dd MMM yyyy',
            default_alert_threshold INTEGER NOT NULL DEFAULT 5,
            default_unit           TEXT NOT NULL DEFAULT 'pcs',
            payment_methods        TEXT NOT NULL DEFAULT 'cash,card,credit',
            created_at             TEXT NOT NULL,
            updated_at             TEXT NOT NULL
          )
        ''');
      }
    }

    if (oldV < 15) {
      final columns = await db.rawQuery('PRAGMA table_info(product_variants)');
      if (columns.isEmpty) {
        final b = db.batch();
        _createProductVariants(b);
        await b.commit(noResult: true);
      }
    }

    if (oldV < 16) {
      final columns = await db.rawQuery('PRAGMA table_info(app_settings)');
      if (!columns.any((c) => c['name'] == 'barcode_lookup_url')) {
        await db.execute('''
          ALTER TABLE app_settings ADD COLUMN barcode_lookup_url TEXT NOT NULL DEFAULT 'http://localhost:8000'
        ''');
      }
    }

    if (oldV < 17) {
      final now = DateTime.now().toIso8601String();
      final cats = SeedData.categories(DateTime.now());
      for (final c in cats) {
        await db.insert('categories', c.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      final prods = SeedData.products(DateTime.now());
      for (final p in prods) {
        await db.insert('products', p.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  /// Re-opens the database after a backup restore, skipping version checks
  /// so the restored data is preserved exactly as-is.
  Future<void> reopenFromBackup(String path) async {
    await _db?.close();
    _db = await openDatabase(path);
    await _db!.execute('PRAGMA foreign_keys = ON');
    _openFuture = null;
  }

  void _dropAll(Batch batch) {
    for (final t in const [
      'app_settings',
      'stock_movements',
      'transaction_items',
      'transactions',
      'suppliers',
      'customers',
      'categories',
      'product_variants',
      'products',
    ]) {
      batch.execute('DROP TABLE IF EXISTS $t');
    }
  }

  void _createProducts(Batch b) {
    b.execute('''
      CREATE TABLE products (
        id              TEXT PRIMARY KEY,
        name            TEXT NOT NULL,
        buy_price       REAL NOT NULL DEFAULT 0,
        sell_price      REAL NOT NULL DEFAULT 0,
        stock           INTEGER NOT NULL DEFAULT 0,
        alert_threshold INTEGER NOT NULL DEFAULT 5,
        emoji           TEXT NOT NULL DEFAULT '📦',
        category        TEXT NOT NULL DEFAULT '',
        brand           TEXT NOT NULL DEFAULT '',
        unit            TEXT NOT NULL DEFAULT 'pcs',
        sku             TEXT NOT NULL DEFAULT '',
        barcode         TEXT NOT NULL DEFAULT '',
        notes           TEXT NOT NULL DEFAULT '',
        image_path      TEXT NOT NULL DEFAULT '',
        is_active       INTEGER NOT NULL DEFAULT 1,
        created_at      TEXT NOT NULL,
        updated_at      TEXT NOT NULL
      )
    ''');
  }

  void _createCategories(Batch b) {
    b.execute('''
      CREATE TABLE categories (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL UNIQUE,
        emoji      TEXT NOT NULL DEFAULT '🏷️',
        created_at TEXT NOT NULL
      )
    ''');
  }

  void _createCustomers(Batch b) {
    b.execute('''
      CREATE TABLE customers (
        id                  TEXT PRIMARY KEY,
        name                TEXT NOT NULL,
        mobile              TEXT NOT NULL DEFAULT '',
        email               TEXT NOT NULL DEFAULT '',
        address             TEXT NOT NULL DEFAULT '',
        gst_vat             TEXT NOT NULL DEFAULT '',
        notes               TEXT NOT NULL DEFAULT '',
        outstanding_balance REAL NOT NULL DEFAULT 0,
        created_at          TEXT NOT NULL,
        updated_at          TEXT NOT NULL
      )
    ''');
  }

  void _createSuppliers(Batch b) {
    b.execute('''
      CREATE TABLE suppliers (
        id                  TEXT PRIMARY KEY,
        name                TEXT NOT NULL,
        contact_person      TEXT NOT NULL DEFAULT '',
        mobile              TEXT NOT NULL DEFAULT '',
        email               TEXT NOT NULL DEFAULT '',
        address             TEXT NOT NULL DEFAULT '',
        gst_vat             TEXT NOT NULL DEFAULT '',
        notes               TEXT NOT NULL DEFAULT '',
        outstanding_balance REAL NOT NULL DEFAULT 0,
        created_at          TEXT NOT NULL,
        updated_at          TEXT NOT NULL
      )
    ''');
  }

  void _createTransactions(Batch b) {
    b.execute('''
      CREATE TABLE transactions (
        id                      TEXT PRIMARY KEY,
        type                    TEXT NOT NULL,
        total_amount            REAL NOT NULL DEFAULT 0,
        discount                REAL NOT NULL DEFAULT 0,
        tax_amount              REAL NOT NULL DEFAULT 0,
        notes                   TEXT NOT NULL DEFAULT '',
        payment_method          TEXT NOT NULL DEFAULT 'cash',
        entity_name             TEXT NOT NULL DEFAULT '',
        entity_id               TEXT NOT NULL DEFAULT '',
        paid_amount             REAL NOT NULL DEFAULT 0,
        original_transaction_id TEXT,
        created_at              TEXT NOT NULL
      )
    ''');
  }

  void _createTransactionItems(Batch b) {
    b.execute('''
      CREATE TABLE transaction_items (
        id                 TEXT PRIMARY KEY,
        transaction_id     TEXT NOT NULL,
        product_id         TEXT NOT NULL,
        product_name       TEXT NOT NULL DEFAULT '',
        product_emoji      TEXT NOT NULL DEFAULT '📦',
        product_image_path TEXT NOT NULL DEFAULT '',
        product_unit       TEXT NOT NULL DEFAULT 'pcs',
        quantity           INTEGER NOT NULL DEFAULT 0,
        price_at_time      REAL NOT NULL DEFAULT 0,
        cost_price_at_time REAL NOT NULL DEFAULT 0,
        discount           REAL NOT NULL DEFAULT 0,
        tax                REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');
  }

  void _createStockMovements(Batch b) {
    b.execute('''
      CREATE TABLE stock_movements (
        id              TEXT PRIMARY KEY,
        product_id      TEXT NOT NULL,
        product_name    TEXT NOT NULL DEFAULT '',
        product_emoji   TEXT NOT NULL DEFAULT '📦',
        product_image_path TEXT NOT NULL DEFAULT '',
        transaction_id  TEXT,
        type            TEXT NOT NULL,
        quantity_change INTEGER NOT NULL,
        reason          TEXT NOT NULL DEFAULT '',
        created_at      TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
      )
    ''');
  }

  void _createProductVariants(Batch b) {
    b.execute('''
      CREATE TABLE product_variants (
        id              TEXT PRIMARY KEY,
        product_id      TEXT NOT NULL,
        name            TEXT NOT NULL DEFAULT '',
        sku             TEXT NOT NULL DEFAULT '',
        buy_price       REAL NOT NULL DEFAULT 0,
        sell_price      REAL NOT NULL DEFAULT 0,
        stock           INTEGER NOT NULL DEFAULT 0,
        alert_threshold INTEGER NOT NULL DEFAULT 5,
        attributes      TEXT NOT NULL DEFAULT '',
        created_at      TEXT NOT NULL,
        updated_at      TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');
  }

  void _createAppSettings(Batch b) {
    b.execute('''
      CREATE TABLE app_settings (
        id                     INTEGER PRIMARY KEY DEFAULT 1,
        currency_symbol        TEXT NOT NULL DEFAULT '\$',
        currency_position      TEXT NOT NULL DEFAULT 'left',
        date_format            TEXT NOT NULL DEFAULT 'dd MMM yyyy',
        default_alert_threshold INTEGER NOT NULL DEFAULT 5,
        default_unit           TEXT NOT NULL DEFAULT 'pcs',
        payment_methods        TEXT NOT NULL DEFAULT 'cash,card,credit',
        barcode_lookup_url     TEXT NOT NULL DEFAULT 'http://localhost:8000',
        created_at             TEXT NOT NULL,
        updated_at             TEXT NOT NULL
      )
    ''');
  }

  void _createIndexes(Batch b) {
    b.execute('CREATE INDEX idx_products_name ON products(name)');
    b.execute('CREATE INDEX idx_products_category ON products(category)');
    b.execute('CREATE INDEX idx_products_stock ON products(stock)');
    b.execute('CREATE INDEX idx_txn_created ON transactions(created_at)');
    b.execute('CREATE INDEX idx_txn_type ON transactions(type)');
    b.execute(
        'CREATE INDEX idx_txn_items_txn ON transaction_items(transaction_id)');
    b.execute(
        'CREATE INDEX idx_txn_items_product ON transaction_items(product_id)');
    b.execute(
        'CREATE INDEX idx_stock_mov_product ON stock_movements(product_id)');
    b.execute(
        'CREATE INDEX idx_stock_mov_created ON stock_movements(created_at)');
  }

  Future<void> _seedIfEmpty(Database db, {bool categoriesOnly = false}) async {
    final now = DateTime.now();
    final cats = SeedData.categories(now);
    await db.transaction((txn) async {
      for (final Category c in cats) {
        await txn.insert(
          'categories',
          c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      if (!categoriesOnly) {
        final prods = SeedData.products(now);
        for (final Product pr in prods) {
          await txn.insert(
            'products',
            pr.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  /// Test / dev helper — drop and recreate all tables, then re-seed.
  /// NEVER called from production code paths; wire it to a dev-only
  /// screen if needed.
  Future<void> resetForTests() async {
    final db = await database;
    final batch = db.batch();
    _dropAll(batch);
    _createProducts(batch);
    _createCategories(batch);
    _createCustomers(batch);
    _createSuppliers(batch);
    _createTransactions(batch);
    _createTransactionItems(batch);
    _createStockMovements(batch);
    _createProductVariants(batch);
    _createAppSettings(batch);
    _createIndexes(batch);
    await batch.commit(noResult: true);
    await _seedIfEmpty(db);
  }

  /// Database file path on disk. Used by BackupService for export/import.
  Future<String> getDatabasePath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, AppConstants.dbName);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _openFuture = null;
  }
}
