import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'supabase_service.dart';

/// Sync service.
///
/// Design goals (replaces the old "wipe local + re-pull" model that could
/// lose data on every launch):
///  - Every local write is recorded in a persistent `sync_queue` table, so a
///    failed/ offline push is retried later instead of being dropped.
///  - `syncAll()` first pushes the queue, then pulls remote rows and MERGES
///    them into local by last-write-wins on a per-table timestamp. Local rows
///    that don't exist remotely are never deleted, so local-only / offline
///    data is preserved.
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

  /// Per-table column used for last-write-wins conflict resolution.
  static const Map<String, String> _tsColumns = {
    'products': 'updated_at',
    'categories': 'created_at',
    'customers': 'updated_at',
    'suppliers': 'updated_at',
    'transactions': 'created_at',
    'transaction_items': 'updated_at',
    'stock_movements': 'created_at',
    'product_variants': 'updated_at',
    'app_settings': 'updated_at',
  };

  static const List<String> _tables = [
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

  DateTime _ts(Object? v) {
    if (v is String && v.isNotEmpty) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Enqueue an upsert operation. The row is persisted to the local queue
  /// immediately, then a best-effort push runs in the background.
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    final id = data['id'];
    if (id == null) return;
    final db = await DatabaseHelper.instance.database;
    await db.insert('sync_queue', {
      'table_name': table,
      'op': 'upsert',
      'row_id': id.toString(),
      'payload': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
    });
    unawaited(_flush());
  }

  /// Enqueue a delete operation.
  Future<void> delete(String table, String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('sync_queue', {
      'table_name': table,
      'op': 'delete',
      'row_id': id,
      'payload': '',
      'created_at': DateTime.now().toIso8601String(),
    });
    unawaited(_flush());
  }

  bool _flushing = false;

  /// Push every queued operation to Supabase. Failures stay in the queue
  /// for the next attempt (no data loss on a flaky connection).
  Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final client = SupabaseService.instance.clientOrNull;
      final uid = await _userId;
      if (client == null || uid == null) return;
      final db = await DatabaseHelper.instance.database;
      final pending = await db.query('sync_queue', orderBy: 'id ASC');
      for (final entry in pending) {
        final id = entry['id'] as int;
        final table = entry['table_name'] as String;
        final op = entry['op'] as String;
        try {
          if (op == 'delete') {
            final rowId = entry['row_id'] as String;
            await client
                .from(table)
                .delete()
                .eq('id', rowId)
                .timeout(const Duration(seconds: 10));
          } else {
            final payload =
                jsonDecode(entry['payload'] as String) as Map<String, dynamic>;
            payload['user_id'] = uid;
            await client
                .from(table)
                .upsert(payload)
                .timeout(const Duration(seconds: 10));
          }
          await db
              .delete('sync_queue', where: 'id = ?', whereArgs: [id]);
        } catch (e) {
          _reportError(table, op, e);
        }
      }
    } finally {
      _flushing = false;
    }
  }

  /// Push local changes, then pull + merge remote data into local without
  /// ever deleting local-only rows.
  Future<void> syncAll() async {
    try {
      await _flush();
      await _mergeFromRemote();
    } catch (e) {
      _reportError('syncAll', 'sync', e);
    }
  }

  Future<void> _mergeFromRemote() async {
    final uid = await _userId;
    final supabase = SupabaseService.instance.clientOrNull;
    if (uid == null || supabase == null) return;
    final db = await DatabaseHelper.instance.database;

    for (final table in _tables) {
      List<Map<String, Object?>> remote;
      try {
        final rows = await supabase
            .from(table)
            .select()
            .eq('user_id', uid)
            .timeout(const Duration(seconds: 15));
        remote = (rows as List).map((r) {
          final map = Map<String, Object?>.from(r as Map);
          map.remove('user_id');
          return map;
        }).toList();
      } catch (e) {
        _reportError(table, 'pull', e);
        continue;
      }

      final tsCol = _tsColumns[table]!;
      final localRows = await db.query(table);
      final localById = <String, Map<String, Object?>>{};
      for (final r in localRows) {
        final key = r['id']?.toString();
        if (key != null) localById[key] = r;
      }

      await db.transaction((txn) async {
        for (final r in remote) {
          final key = r['id']?.toString();
          if (key == null) continue;
          final local = localById[key];
          if (local == null) {
            await txn.insert(table, r,
                conflictAlgorithm: ConflictAlgorithm.ignore);
          } else if (_ts(r[tsCol]).isAfter(_ts(local[tsCol]))) {
            await txn.delete(table, where: 'id = ?', whereArgs: [key]);
            await txn.insert(table, r);
          }
        }
      });
    }
  }
}
