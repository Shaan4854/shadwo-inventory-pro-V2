-- Shadow Inventory Pro v2 — Supabase schema
-- Run this in the Supabase SQL Editor to set up all tables + RLS policies.

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Categories ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL UNIQUE,
  emoji      TEXT NOT NULL DEFAULT '🏷️',
  created_at TEXT NOT NULL,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own categories"
  ON categories FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── Products ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
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
  updated_at      TEXT NOT NULL,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own products"
  ON products FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_stock ON products(stock);

-- ─── Customers ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
  id                  TEXT PRIMARY KEY,
  name                TEXT NOT NULL,
  mobile              TEXT NOT NULL DEFAULT '',
  email               TEXT NOT NULL DEFAULT '',
  address             TEXT NOT NULL DEFAULT '',
  gst_vat             TEXT NOT NULL DEFAULT '',
  notes               TEXT NOT NULL DEFAULT '',
  outstanding_balance REAL NOT NULL DEFAULT 0,
  created_at          TEXT NOT NULL,
  updated_at          TEXT NOT NULL,
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own customers"
  ON customers FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── Suppliers ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS suppliers (
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
  updated_at          TEXT NOT NULL,
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own suppliers"
  ON suppliers FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── Transactions ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
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
  created_at              TEXT NOT NULL,
  user_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own transactions"
  ON transactions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_txn_created ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_txn_type ON transactions(type);

-- ─── Transaction Items ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_items (
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
  updated_at         TEXT NOT NULL DEFAULT '',
  variant_id         TEXT NOT NULL DEFAULT '',
  variant_name       TEXT NOT NULL DEFAULT '',
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own transaction_items"
  ON transaction_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_txn_items_txn ON transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_txn_items_product ON transaction_items(product_id);

-- ─── Stock Movements ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stock_movements (
  id                TEXT PRIMARY KEY,
  product_id        TEXT NOT NULL,
  product_name      TEXT NOT NULL DEFAULT '',
  product_emoji     TEXT NOT NULL DEFAULT '📦',
  product_image_path TEXT NOT NULL DEFAULT '',
  transaction_id    TEXT,
  type              TEXT NOT NULL,
  quantity_change   INTEGER NOT NULL,
  reason            TEXT NOT NULL DEFAULT '',
  created_at        TEXT NOT NULL,
  variant_id        TEXT NOT NULL DEFAULT '',
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
);

ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own stock_movements"
  ON stock_movements FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_stock_mov_product ON stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_mov_created ON stock_movements(created_at);

-- ─── Product Variants ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS product_variants (
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
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own product_variants"
  ON product_variants FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── App Settings ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_settings (
  id                     INTEGER PRIMARY KEY DEFAULT 1,
  currency_symbol        TEXT NOT NULL DEFAULT '$',
  currency_position      TEXT NOT NULL DEFAULT 'left',
  date_format            TEXT NOT NULL DEFAULT 'dd MMM yyyy',
  default_alert_threshold INTEGER NOT NULL DEFAULT 5,
  default_unit           TEXT NOT NULL DEFAULT 'pcs',
  payment_methods        TEXT NOT NULL DEFAULT 'cash,card,credit',
  barcode_lookup_url     TEXT NOT NULL DEFAULT 'http://localhost:8000',
  created_at             TEXT NOT NULL,
  updated_at             TEXT NOT NULL,
  user_id                UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own app_settings"
  ON app_settings FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── Sync Queue ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sync_queue (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  op         TEXT NOT NULL,
  row_id     TEXT NOT NULL,
  payload    TEXT NOT NULL,
  created_at TEXT NOT NULL,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own sync_queue"
  ON sync_queue FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
