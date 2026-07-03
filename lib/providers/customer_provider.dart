import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider({CustomerRepository? repository, Uuid? uuid})
      : _repo = repository ?? CustomerRepository(),
        _uuid = uuid ?? const Uuid();

  final CustomerRepository _repo;
  final Uuid _uuid;

  List<Customer> _all = const [];
  bool _loading = false;
  Object? _error;
  String _search = '';

  List<Customer> get all => List.unmodifiable(_all);
  bool get isLoading => _loading;
  Object? get error => _error;
  String get search => _search;
  int get totalCustomers => _all.length;

  List<Customer> get filtered {
    if (_search.trim().isEmpty) return List.unmodifiable(_all);
    final q = _search.toLowerCase().trim();
    return _all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.mobile.contains(q) ||
            c.email.toLowerCase().contains(q))
        .toList();
  }

  Customer? byId(String id) {
    for (final c in _all) {
      if (c.id == id) return c;
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

  Future<Customer> addCustomer({
    required String name,
    required String mobile,
    required String email,
    required String address,
    required String gstVat,
    required String notes,
  }) async {
    final now = DateTime.now();
    final c = Customer(
      id: _uuid.v4(),
      name: name,
      mobile: mobile,
      email: email,
      address: address,
      gstVat: gstVat,
      notes: notes,
      outstandingBalance: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.insert(c);
    await load();
    return c;
  }

  Future<void> updateCustomer(Customer c) async {
    await _repo.update(c);
    await load();
  }

  Future<void> deleteCustomer(String id) async {
    await _repo.delete(id);
    _all = _all.where((c) => c.id != id).toList();
    notifyListeners();
  }
}
