import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  SupabaseClient? get clientOrNull =>
      _initialized ? Supabase.instance.client : null;

  Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || key == null) {
      throw Exception(
        'Supabase credentials not found. Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in .env',
      );
    }
    await Supabase.initialize(url: url, publishableKey: key);
    _initialized = true;
  }

  Session? get session => clientOrNull?.auth.currentSession;
  User? get user => clientOrNull?.auth.currentUser;

  Future<void> signOut() async {
    await clientOrNull?.auth.signOut();
  }
}
