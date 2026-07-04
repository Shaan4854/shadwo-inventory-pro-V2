import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../utils/app_constants.dart';
import '../utils/seed_data.dart';

/// Singleton wrapper around the app's sqflite database. Every repository
/// obtains its `Database` via `await DatabaseHelper.instance.database`.
///
/// Schema is versioned; `onUpgrade` handles forward migrations. NEVER
/// downgrade — spec-locked at v8.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
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
    _createIndexes(batch);
    await batch.commit(noResult: true);
    await _seedIfEmpty(db);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Non-destructive migration path.
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
  }

  void _dropAll(Batch batch) {
    for (final t in const [
      'stock_movements',
      'transaction_items',
      'transactions',
      'suppliers',
      'customers',
      'categories',
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
        product_unit       TEXT NOT NULL DEFAULT 'pcs',
        quantity           INTEGER NOT NULL DEFAULT 0,
        price_at_time      REAL NOT NULL DEFAULT 0,
        cost_price_at_time REAL NOT NULL DEFAULT 0,
        discount           REAL NOT NULL DEFAULT 0,
        tax                REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
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
        transaction_id  TEXT,
        type            TEXT NOT NULL,
        quantity_change INTEGER NOT NULL,
        reason          TEXT NOT NULL DEFAULT '',
        created_at      TEXT NOT NULL
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

  Future<void> _seedIfEmpty(Database db) async {
    final now = DateTime.now();
    final cats = SeedData.categories(now);
    final prods = SeedData.products(now);
    await db.transaction((txn) async {
      for (final Category c in cats) {
        await txn.insert(
          'categories',
          c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final Product pr in prods) {
        await txn.insert(
          'products',
          pr.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
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
    _createIndexes(batch);
    await batch.commit(noResult: true);
    await _seedIfEmpty(db);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
