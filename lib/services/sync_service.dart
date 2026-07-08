import 'dart:async';

import '../database/database_helper.dart';
import 'supabase_service.dart';

/// Fire-and-forget sync to Supabase. Writes are non-blocking — local
/// sqflite is always the source of truth. On login, pulls the user's
/// entire dataset from Supabase and replaces local data.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  Future<String?> get _userId async {
    final user = SupabaseService.instance.user;
    return user?.id;
  }

  // ── Push (fire-and-forget) ────────────────────────────────────────

  Future<void> upsert(String table, Map<String, dynamic> data) async {
    final uid = await _userId;
    if (uid == null) return;
    unawaited(_doUpsert(table, data, uid));
  }

  Future<void> delete(String table, String id) async {
    final uid = await _userId;
    if (uid == null) return;
    unawaited(_doDelete(table, id, uid));
  }

  Future<void> _doUpsert(
      String table, Map<String, dynamic> data, String uid) async {
    try {
      data['user_id'] = uid;
      await SupabaseService.instance.client
          .from(table)
          .upsert(data)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
    }
  }

  Future<void> _doDelete(
      String table, String id, String uid) async {
    try {
      await SupabaseService.instance.client
          .from(table)
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
    }
  }

  // ── Pull (on login — replaces local DB) ───────────────────────────

  Future<void> pullFromSupabase() async {
    final uid = await _userId;
    if (uid == null) return;
    try {
      final db = await DatabaseHelper.instance.database;

      final tables = [
        'products',
        'categories',
        'customers',
        'suppliers',
        'transactions',
        'transaction_items',
        'stock_movements',
      ];

      await db.transaction((txn) async {
        for (final t in tables.reversed) {
          await txn.delete(t);
        }

        for (final t in tables) {
          final rows = await SupabaseService.instance.client
              .from(t)
              .select()
              .eq('user_id', uid)
              .timeout(const Duration(seconds: 15));
          for (final row in rows) {
            final map = Map<String, Object?>.from(row as Map);
            map.remove('user_id');
            map.remove('created_at');
            map.remove('updated_at');
            await txn.insert(t, map);
          }
        }
      });
    } catch (_) {
    }
  }
}
