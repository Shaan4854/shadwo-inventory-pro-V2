import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../services/sync_service.dart';

enum AuthStatus { uninitialized, authenticated, offline }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn =>
      _status == AuthStatus.authenticated || _status == AuthStatus.offline;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Check for existing session
    final existing = SupabaseService.instance.session;
    if (existing != null) {
      _user = existing.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }

    // Listen for auth state changes (handles OAuth redirect callback)
    SupabaseService.instance.clientOrNull?.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _user = session.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        SyncService.instance.syncAll();
      } else {
        _user = null;
        _status = AuthStatus.uninitialized;
        notifyListeners();
      }
    });

    try {
      final client = SupabaseService.instance.clientOrNull;
      if (client == null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
      // Anonymous fallback for offline/first launch
      final res = await client.auth.signInAnonymously();
      _user = res.user;
      _status = AuthStatus.authenticated;
      await SyncService.instance.syncAll();
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Supabase init failed, running offline: $e');
      _status = AuthStatus.offline;
      notifyListeners();
    }
  }

  /// Sign in with Google via Supabase OAuth (opens browser).
  /// Configure the Google OAuth provider in Supabase Dashboard > Authentication > Providers.
  Future<bool> signInWithGoogle() async {
    final client = SupabaseService.instance.clientOrNull;
    if (client == null) {
      _error = 'Supabase not configured';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.shadow-inventory-pro://login-callback/',
        authScreenLaunchMode: LaunchMode.inAppWebView,
      );
      // The onAuthStateChange listener will handle the session
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Google sign-in failed: $e');
      _error = 'Sign-in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email/password.
  Future<bool> signInWithEmail(String email, String password) async {
    final client = SupabaseService.instance.clientOrNull;
    if (client == null) {
      _error = 'Supabase not configured';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = res.user;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      _error = null;
      notifyListeners();
      await SyncService.instance.syncAll();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Email sign-in failed: $e');
      _error = 'Sign-in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a new account with email/password.
  Future<bool> signUpWithEmail(String email, String password) async {
    final client = SupabaseService.instance.clientOrNull;
    if (client == null) {
      _error = 'Supabase not configured';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
      );
      _user = res.user;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      _error = null;
      notifyListeners();
      await SyncService.instance.syncAll();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Sign-up failed: $e');
      _error = 'Sign-up failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Continue as guest (anonymous auth or offline mode).
  Future<void> continueAsGuest() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = SupabaseService.instance.clientOrNull;
      if (client == null) {
        _status = AuthStatus.offline;
      } else {
        final res = await client.auth.signInAnonymously();
        _user = res.user;
        _status = AuthStatus.authenticated;
        await SyncService.instance.syncAll();
      }
    } catch (e) {
      debugPrint('AuthProvider: Anonymous sign-in failed: $e');
      _status = AuthStatus.offline;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    _user = null;
    _status = AuthStatus.uninitialized;
    _error = null;
    notifyListeners();
  }
}
