import 'package:flutter/foundation.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/market_model.dart';

class CartProvider extends ChangeNotifier {
  static const double marketFee = 0.75;

  final Map<String, CartItem> _items = {};

  Market? _pickupMarket;
  PickupSlot? _pickupSlot;

  Map<String, CartItem> get items =>
      Map.unmodifiable(_items);

  List<CartItem> get itemList =>
      _items.values.toList();

  bool get isEmpty => _items.isEmpty;

  Market? get pickupMarket =>
      _pickupMarket;

  PickupSlot? get pickupSlot =>
      _pickupSlot;

  int get itemCount =>
      _items.values.fold(
        0,
        (sum, item) =>
            sum + item.quantity.ceil(),
      );

  double get subtotal =>
      _items.values.fold(
        0,
        (sum, item) =>
            sum + item.lineTotal,
      );

  double get fee =>
      _items.isEmpty ? 0 : marketFee;

  double get total =>
      subtotal + fee;


  Map<String, List<CartItem>> get itemsByFarmer {
    final grouped =
        <String, List<CartItem>>{};

    for (final item in _items.values) {
      grouped
          .putIfAbsent(
            item.product.farmerId,
            () => [],
          )
          .add(item);
    }

    return grouped;
  }

  void addItem(
    Product product, {
    double quantity = 1,
  }) {
    if (!product.isInStock) {
      return;
    }

    final safeQuantity =
        quantity.clamp(
      0.1,
      product.stockQty.toDouble(),
    );

    final existing =
        _items[product.id];

    if (existing != null) {
      existing.quantity =
          (existing.quantity + safeQuantity)
              .clamp(
                0.1,
                product.stockQty
                    .toDouble(),
              )
              .toDouble();
    } else {
      _items[product.id] = CartItem(
        product: product,
        quantity: safeQuantity.toDouble(),
      );
    }

    notifyListeners();
  }

  void updateQuantity(
    String productId,
    double quantity,
  ) {
    final existing =
        _items[productId];

    if (existing == null) {
      return;
    }

    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      existing.quantity =
          quantity
              .clamp(
                0.1,
                existing.product.stockQty
                    .toDouble(),
              )
              .toDouble();
    }

    notifyListeners();
  }

  void removeItem(
    String productId,
  ) {
    _items.remove(productId);
    notifyListeners();
  }

  void setPickupMarket(
    Market market,
  ) {
    _pickupMarket = market;
    _pickupSlot = null;
    notifyListeners();
  }

  void setPickupSlot(
    PickupSlot slot,
  ) {
    _pickupSlot = slot;
    notifyListeners();
  }

  bool get canCheckout =>
      _items.isNotEmpty &&
      _pickupMarket != null &&
      _pickupSlot != null;

  void clear() {
    _items.clear();
    _pickupSlot = null;
    notifyListeners();
  }
}