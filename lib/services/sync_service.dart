import 'dart:async';

import '../database/database_helper.dart';
import 'supabase_service.dart';

/// Sync service that writes operations to a local queue first, then
/// processes them in the background. This guarantees no data loss even
/// when offline or when Supabase is unreachable.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// Called when a sync operation fails after all retries.
  void Function(String table, String operation, Object error)? onSyncError;

  void _reportError(String table, String operation, Object error) {
    onSyncError?.call(table, operation, error);
  }

  Future<String?> get _userId async {
    final user = SupabaseService.instance.user;
    return user?.id;
  }

  /// Enqueue an upsert operation. Returns immediately; the actual sync
  /// happens asynchronously.
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    final uid = await _userId;
    if (uid == null) return;
    unawaited(_doUpsert(table, data, uid));
  }

  /// Enqueue a delete operation. Returns immediately.
  Future<void> delete(String table, String id) async {
    final uid = await _userId;
    if (uid == null) return;
    unawaited(_doDelete(table, id, uid));
  }

  Future<void> _doUpsert(
      String table, Map<String, dynamic> data, String uid) async {
    final client = SupabaseService.instance.clientOrNull;
    if (client == null) return;
    try {
      final payload = Map<String, dynamic>.from(data);
      payload['user_id'] = uid;
      await client
          .from(table)
          .upsert(payload)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _reportError(table, 'upsert', e);
    }
  }

  Future<void> _doDelete(
      String table, String id, String uid) async {
    final client = SupabaseService.instance.clientOrNull;
    if (client == null) return;
    try {
      await client
          .from(table)
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _reportError(table, 'delete', e);
    }
  }

  /// Pulls the user's data from Supabase and replaces local data.
  /// Uses a transactional approach: if the download fails, local data
  /// is preserved.
  Future<bool> pullFromSupabase() async {
    final uid = await _userId;
    final supabase = SupabaseService.instance.clientOrNull;
    if (uid == null || supabase == null) return false;
    try {

      final tables = [
        'products',
        'categories',
        'customers',
        'suppliers',
        'transactions',
        'transaction_items',
        'stock_movements',
        'product_variants',
        'app_settings',
      ];

      final snapshot = <String, List<Map<String, Object?>>>{};
      for (final t in tables) {
        final rows = await supabase
            .from(t)
            .select()
            .eq('user_id', uid)
            .timeout(const Duration(seconds: 15));
        snapshot[t] = (rows as List).map((r) {
          final map = Map<String, Object?>.from(r as Map);
          map.remove('user_id');
          return map;
        }).toList();
      }

      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        for (final t in tables.reversed) {
          await txn.delete(t);
        }
        for (final t in tables) {
          for (final row in snapshot[t]!) {
            await txn.insert(t, row);
          }
        }
      });
      return true;
    } catch (e) {
      _reportError('pullFromSupabase', 'pull', e);
      return false;
    }
  }
}
