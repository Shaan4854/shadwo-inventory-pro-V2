import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  SupplierProvider({SupplierRepository? repository, Uuid? uuid})
      : _repo = repository ?? SupplierRepository(),
        _uuid = uuid ?? const Uuid();

  final SupplierRepository _repo;
  final Uuid _uuid;

  List<Supplier> _all = const [];
  bool _loading = false;
  Object? _error;
  String _search = '';

  List<Supplier> get all => List.unmodifiable(_all);
  bool get isLoading => _loading;
  Object? get error => _error;
  String get search => _search;
  int get totalSuppliers => _all.length;

  List<Supplier> get filtered {
    if (_search.trim().isEmpty) return List.unmodifiable(_all);
    final q = _search.toLowerCase().trim();
    return _all
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.contactPerson.toLowerCase().contains(q) ||
            s.mobile.contains(q) ||
            s.email.toLowerCase().contains(q))
        .toList();
  }

  Supplier? byId(String id) {
    for (final s in _all) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repo.getAll();
    } catch (e) {
      _error = e;
      _all = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String q) {
    if (q == _search) return;
    _search = q;
    notifyListeners();
  }

  Future<Supplier> addSupplier({
    required String name,
    required String contactPerson,
    required String mobile,
    required String email,
    required String address,
    required String gstVat,
    required String notes,
  }) async {
    final now = DateTime.now();
    final s = Supplier(
      id: _uuid.v4(),
      name: name,
      contactPerson: contactPerson,
      mobile: mobile,
      email: email,
      address: address,
      gstVat: gstVat,
      notes: notes,
      outstandingBalance: 0,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _repo.insert(s);
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
    return s;
  }

  Future<void> updateSupplier(Supplier s) async {
    try {
      await _repo.update(s);
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _repo.delete(id);
      _all = _all.where((s) => s.id != id).toList();
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }
}
