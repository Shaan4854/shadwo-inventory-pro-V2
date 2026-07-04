import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider({CategoryRepository? repository, Uuid? uuid})
      : _repo = repository ?? CategoryRepository(),
        _uuid = uuid ?? const Uuid();

  final CategoryRepository _repo;
  final Uuid _uuid;

  List<Category> _all = const [];
  bool _loading = false;
  Object? _error;

  List<Category> get all => List.unmodifiable(_all);
  bool get isLoading => _loading;
  Object? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repo.getAll();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Category> add({required String name, String emoji = '🏷️'}) async {
    if (_all.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      throw Exception('A category with this name already exists.');
    }
    final c = Category(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    await _repo.insert(c);
    await load();
    return c;
  }
}
