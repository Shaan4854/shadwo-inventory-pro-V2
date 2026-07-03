import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider({
    required CustomerRepository customerRepository,
  }) : _customerRepository = customerRepository;

  final CustomerRepository _customerRepository;
  final List<Customer> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  UnmodifiableListView<Customer> get customers => UnmodifiableListView(_customers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customers = await _customerRepository.getCustomers();
      _customers.clear();
      _customers.addAll(customers);
    } catch (e) {
      _errorMessage = 'Failed to load customers.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      await _customerRepository.addCustomer(customer);
      _customers.add(customer);
      _customers.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add customer.';
      notifyListeners();
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _customerRepository.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        _customers.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update customer.';
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _customerRepository.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete customer.';
      notifyListeners();
    }
  }

  Future<void> updateCustomerBalance(String customerId, double amountChange) async {
    try {
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        final customer = _customers[index];
        final updatedCustomer = customer.copyWith(
          outstandingBalance: customer.outstandingBalance + amountChange,
          updatedAt: DateTime.now(),
        );
        await _customerRepository.updateCustomer(updatedCustomer);
        _customers[index] = updatedCustomer;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update customer balance.';
      notifyListeners();
    }
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    final lowerQuery = query.toLowerCase();
    return _customers.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) ||
          c.mobile.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
