import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/customer.dart';
import '../../models/product.dart';

/// Ephemeral cart used by the POS + Purchase screens.
class CartState extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};
  Customer? _customer;
  String? _customName;

  List<CartLine> get lines => List.unmodifiable(_lines.values);
  int get itemCount => _lines.length;
  int get totalUnits =>
      _lines.values.fold<int>(0, (s, l) => s + l.quantity);
  double get subtotal => double.parse(
      _lines.values.fold<double>(0, (s, l) => s + l.lineTotal).toStringAsFixed(2));

  double _discount = 0;
  double _tax = 0;

  double get discount => _discount;
  double get tax => _tax;
  Customer? get customer => _customer;
  String get customerName => _customName ?? _customer?.name ?? '';

  double get total {
    final t = subtotal - _discount + _tax;
    return double.parse((t < 0 ? 0 : t).toStringAsFixed(2));
  }

  bool contains(String productId) => _lines.containsKey(productId);
  CartLine? line(String productId) => _lines[productId];

  void setCustomer(Customer? c) {
    _customer = c;
    _customName = null;
    notifyListeners();
  }

  void setCustomName(String name) {
    _customName = name.trim().isEmpty ? null : name.trim();
    if (_customName != null) _customer = null;
    notifyListeners();
  }

  void addOrIncrement(Product p, {int by = 1}) {
    final existing = _lines[p.id];
    if (existing == null) {
      _lines[p.id] = CartLine(product: p, quantity: by);
    } else {
      _lines[p.id] = existing.copyWith(quantity: existing.quantity + by);
    }
    notifyListeners();
  }

  void setQuantity(String productId, int qty) {
    final existing = _lines[productId];
    if (existing == null) return;
    if (qty <= 0) {
      _lines.remove(productId);
    } else {
      _lines[productId] = existing.copyWith(quantity: qty);
    }
    notifyListeners();
  }

  void setLineDiscount(String productId, double discount) {
    final existing = _lines[productId];
    if (existing == null) return;
    _lines[productId] = existing.copyWith(
      discount: discount < 0 ? 0 : discount,
    );
    notifyListeners();
  }

  void remove(String productId) {
    _lines.remove(productId);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _customer = null;
    _customName = null;
    _discount = 0;
    _tax = 0;
    notifyListeners();
  }

  void setDiscount(double v) {
    _discount = v < 0 ? 0 : v;
    notifyListeners();
  }

  void setTax(double v) {
    _tax = v < 0 ? 0 : v;
    notifyListeners();
  }

  Map<String, dynamic> toSnapshot() {
    return {
      'lines': _lines.values.map((l) => l.toJson()).toList(),
      'customerId': _customer?.id,
      'customName': _customName,
      'discount': _discount,
      'tax': _tax,
    };
  }

  void restoreFromSnapshot(Map<String, dynamic> snap, List<Product> products, {List<Customer>? customers}) {
    _lines.clear();
    for (final lj in snap['lines'] as List) {
      final l = lj as Map<String, dynamic>;
      final pid = l['productId'] as String;
      final product = products.cast<Product?>().firstWhere(
            (p) => p?.id == pid,
            orElse: () => null,
          );
      if (product == null) continue;
      _lines[pid] = CartLine(
        product: product,
        quantity: l['quantity'] as int,
      );
      final d = l['discount'] as num;
      if (d > 0) _lines[pid] = _lines[pid]!.copyWith(discount: d.toDouble());
    }
    final cid = snap['customerId'] as String?;
    if (cid != null && cid.isNotEmpty && customers != null) {
      _customer = customers.cast<Customer?>().firstWhere(
            (c) => c?.id == cid,
            orElse: () => null,
          );
    } else {
      _customer = null;
    }
    _customName = snap['customName'] as String?;
    _discount = (snap['discount'] as num).toDouble();
    _tax = (snap['tax'] as num).toDouble();
    notifyListeners();
  }
}

class CartLine {
  const CartLine({required this.product, required this.quantity, this.discount = 0});
  final Product product;
  final int quantity;
  final double discount;

  double get unitPrice => product.sellPrice;
  double get lineTotal => (quantity * unitPrice) - discount;

  CartLine copyWith({Product? product, int? quantity, double? discount}) => CartLine(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        discount: discount ?? this.discount,
      );

  Map<String, dynamic> toJson() => {
        'productId': product.id,
        'quantity': quantity,
        'discount': discount,
      };
}

/// In-memory held cart storage (lost on app restart).
class HeldCartStore {
  HeldCartStore._();
  static final _held = <Map<String, dynamic>>[];

  static List<Map<String, dynamic>> get all => List.unmodifiable(_held);
  static int get count => _held.length;

  static void hold(Map<String, dynamic> snap) {
    snap['_heldAt'] = DateTime.now().toIso8601String();
    _held.add(snap);
  }

  static Map<String, dynamic>? resume(int index) {
    if (index < 0 || index >= _held.length) return null;
    return _held.removeAt(index);
  }

  static void discard(int index) {
    if (index >= 0 && index < _held.length) _held.removeAt(index);
  }

  static void clear() => _held.clear();
}
