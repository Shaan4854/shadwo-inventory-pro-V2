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

  /// Cart lines are keyed by product id, or product id + variant id when a
  /// specific variant of the product is in the cart.
  String _key(String productId, String variantId) =>
      variantId.isEmpty ? productId : '$productId::variantId';

  bool contains(String productId, [String variantId = '']) =>
      _lines.containsKey(_key(productId, variantId));
  CartLine? line(String productId, [String variantId = '']) =>
      _lines[_key(productId, variantId)];

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

  void addOrIncrement(
    Product p, {
    int by = 1,
    String variantId = '',
    String variantName = '',
  }) {
    final key = _key(p.id, variantId);
    final existing = _lines[key];
    if (existing == null) {
      _lines[key] = CartLine(
        product: p,
        quantity: by,
        variantId: variantId,
        variantName: variantName,
      );
    } else {
      _lines[key] = existing.copyWith(quantity: existing.quantity + by);
    }
    notifyListeners();
  }

  void setQuantity(String productId, int qty, [String variantId = '']) {
    final key = _key(productId, variantId);
    final existing = _lines[key];
    if (existing == null) return;
    if (qty <= 0) {
      _lines.remove(key);
    } else {
      _lines[key] = existing.copyWith(quantity: qty);
    }
    notifyListeners();
  }

  void setLineDiscount(String productId, double discount, [String variantId = '']) {
    final key = _key(productId, variantId);
    final existing = _lines[key];
    if (existing == null) return;
    _lines[key] = existing.copyWith(
      discount: discount < 0 ? 0 : discount,
    );
    notifyListeners();
  }

  void remove(String productId, [String variantId = '']) {
    _lines.remove(_key(productId, variantId));
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
      final variantId = (l['variantId'] as String?) ?? '';
      final key = _key(pid, variantId);
      _lines[key] = CartLine(
        product: product,
        quantity: l['quantity'] as int,
        variantId: variantId,
        variantName: (l['variantName'] as String?) ?? '',
      );
      final d = l['discount'] as num;
      if (d > 0) _lines[key] = _lines[key]!.copyWith(discount: d.toDouble());
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
  const CartLine({
    required this.product,
    required this.quantity,
    this.discount = 0,
    this.variantId = '',
    this.variantName = '',
  });
  final Product product;
  final int quantity;
  final double discount;
  final String variantId;
  final String variantName;

  bool get hasVariant => variantId.isNotEmpty;

  double get unitPrice => product.sellPrice;
  double get lineTotal => (quantity * unitPrice) - discount;

  CartLine copyWith({
    Product? product,
    int? quantity,
    double? discount,
    String? variantId,
    String? variantName,
  }) =>
      CartLine(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        discount: discount ?? this.discount,
        variantId: variantId ?? this.variantId,
        variantName: variantName ?? this.variantName,
      );

  Map<String, dynamic> toJson() => {
        'productId': product.id,
        'quantity': quantity,
        'discount': discount,
        'variantId': variantId,
        'variantName': variantName,
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
