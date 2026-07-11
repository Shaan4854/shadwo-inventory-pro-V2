import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../services/sync_service.dart';

enum AuthStatus { uninitialized, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final existing = SupabaseService.instance.session;
    if (existing != null) {
      _user = existing.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }
    try {
      final client = SupabaseService.instance.clientOrNull;
      if (client == null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
      final res = await client.auth.signInAnonymously();
      _user = res.user;
      _status = AuthStatus.authenticated;
      await SyncService.instance.syncAll();
      notifyListeners();
    } catch (_) {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    _user = null;
    _status = AuthStatus.uninitialized;
    notifyListeners();
  }
}
