import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import '../utils/formatters.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsRepository? repository})
      : _repo = repository ?? SettingsRepository();

  final SettingsRepository _repo;

  AppSettings _settings = const AppSettings();
  bool _loading = false;
  Object? _error;

  AppSettings get settings => _settings;
  bool get isLoading => _loading;
  Object? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _settings = await _repo.get();
      _applySettings();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> update(AppSettings updated) async {
    _error = null;
    try {
      await _repo.save(updated);
      _settings = updated;
      _applySettings();
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  void _applySettings() {
    Formatters.setCurrency(
      _settings.currencySymbol,
      left: _settings.currencyPosition == 'left',
    );
  }
}
