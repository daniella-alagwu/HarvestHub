import 'package:flutter/foundation.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/market_model.dart';

class CartProvider extends ChangeNotifier {
  /// Flat per-order fee charged by the marketplace on top of subtotal,
  /// shown as "Market fee" at checkout — not a farmer-set price.
  static const double marketFee = 0.75;

  final Map<String, CartItem> _items = {};
  Market? _pickupMarket;
  PickupSlot? _pickupSlot;

  Map<String, CartItem> get items => Map.unmodifiable(_items);
  List<CartItem> get itemList => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  Market? get pickupMarket => _pickupMarket;
  PickupSlot? get pickupSlot => _pickupSlot;

  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity.ceil());

  double get subtotal =>
      _items.values.fold(0, (sum, item) => sum + item.lineTotal);

  double get fee => _items.isEmpty ? 0 : marketFee;

  double get total => subtotal + fee;

  void addItem(Product product, {double quantity = 1}) {
    final existing = _items[product.id];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      final existing = _items[productId];
      if (existing != null) existing.quantity = quantity;
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void setPickupMarket(Market market) {
    _pickupMarket = market;
    _pickupSlot = null;
    notifyListeners();
  }

  void setPickupSlot(PickupSlot slot) {
    _pickupSlot = slot;
    notifyListeners();
  }

  bool get canCheckout =>
      _items.isNotEmpty && _pickupMarket != null && _pickupSlot != null;

  void clear() {
    _items.clear();
    _pickupSlot = null;
    notifyListeners();
  }
}