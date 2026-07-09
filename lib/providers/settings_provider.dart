import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import '../screens/products/barcode_scan_screen.dart';
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
      final preserved = updated.createdAt == null
          ? updated.copyWith(createdAt: _settings.createdAt ?? DateTime.now())
          : updated;
      await _repo.save(preserved);
      _settings = preserved;
      _applySettings();
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
    }
  }

  void _applySettings() {
    Formatters.setCurrency(
      _settings.currencySymbol,
      left: _settings.currencyPosition == 'left',
    );
    Formatters.setDateFormat(_settings.dateFormat);
    setSelfHostedUrl(_settings.barcodeLookupUrl);
  }
}
