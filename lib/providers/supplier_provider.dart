import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  SupplierProvider({
    required SupplierRepository supplierRepository,
  }) : _supplierRepository = supplierRepository;

  final SupplierRepository _supplierRepository;
  final List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  UnmodifiableListView<Supplier> get suppliers => UnmodifiableListView(_suppliers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Supplier> get recentSuppliers {
    // Avoid full-list sort: find top 5 by updatedAt using a partial scan
    if (_suppliers.length <= 5) return List<Supplier>.from(_suppliers);
    // Manual top-5 selection to avoid O(n log n) sort
    final top5 = <Supplier>[];
    Supplier? lowest;
    for (final s in _suppliers) {
      if (top5.length < 5) {
        top5.add(s);
        lowest = top5.reduce((a, b) => a.updatedAt.isBefore(b.updatedAt) ? a : b);
      } else if (lowest != null && s.updatedAt.isAfter(lowest.updatedAt)) {
        top5.remove(lowest);
        top5.add(s);
        lowest = top5.reduce((a, b) => a.updatedAt.isBefore(b.updatedAt) ? a : b);
      }
    }
    top5.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return top5;
  }

  Future<void> loadSuppliers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final suppliers = await _supplierRepository.getSuppliers();
      _suppliers.clear();
      _suppliers.addAll(suppliers);
    } catch (e) {
      _errorMessage = 'Failed to load suppliers.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _supplierRepository.addSupplier(supplier);
      _suppliers.add(supplier);
      _suppliers.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add supplier.';
      notifyListeners();
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _supplierRepository.updateSupplier(supplier);
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        _suppliers[index] = supplier;
        _suppliers.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update supplier.';
      notifyListeners();
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _supplierRepository.deleteSupplier(id);
      _suppliers.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete supplier.';
      notifyListeners();
    }
  }

  Future<void> updateSupplierBalance(String supplierId, double amountChange) async {
    try {
      final index = _suppliers.indexWhere((s) => s.id == supplierId);
      if (index != -1) {
        final supplier = _suppliers[index];
        final updatedSupplier = supplier.copyWith(
          outstandingBalance: supplier.outstandingBalance + amountChange,
          updatedAt: DateTime.now(),
        );
        await _supplierRepository.updateSupplier(updatedSupplier);
        _suppliers[index] = updatedSupplier;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update supplier balance.';
      notifyListeners();
    }
  }

  List<Supplier> searchSuppliers(String query) {
    if (query.isEmpty) return _suppliers;
    final lowerQuery = query.toLowerCase();
    return _suppliers.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          s.mobile.toLowerCase().contains(lowerQuery) ||
          s.contactPerson.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
