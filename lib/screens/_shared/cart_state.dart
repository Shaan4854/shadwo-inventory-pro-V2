import 'package:flutter/foundation.dart';

import '../../models/product.dart';

/// Ephemeral cart used by the POS + Purchase screens. NOT a provider —
/// screen-local because carts are per-screen sessions that vanish on
/// confirm/cancel. Rebuild consumers via `ChangeNotifier` inside the
/// screen's `StatefulWidget`.
class CartState extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => List.unmodifiable(_lines.values);
  int get itemCount => _lines.length;
  int get totalUnits =>
      _lines.values.fold<int>(0, (s, l) => s + l.quantity);
  double get subtotal =>
      _lines.values.fold<double>(0, (s, l) => s + l.lineTotal);

  double _discount = 0;
  double _tax = 0;

  double get discount => _discount;
  double get tax => _tax;
  double get total {
    final t = subtotal - _discount + _tax;
    return t < 0 ? 0 : t;
  }

  bool contains(String productId) => _lines.containsKey(productId);
  CartLine? line(String productId) => _lines[productId];

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

  void remove(String productId) {
    _lines.remove(productId);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
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
}

class CartLine {
  const CartLine({required this.product, required this.quantity});
  final Product product;
  final int quantity;

  double get unitPrice => product.sellPrice;
  double get lineTotal => quantity * unitPrice;

  CartLine copyWith({Product? product, int? quantity}) => CartLine(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
      );
}
