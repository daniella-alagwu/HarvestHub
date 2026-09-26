import 'product_model.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});

  final Product product;
  double quantity;

  double get lineTotal => product.pricePerUnit * quantity;

  String get quantityLabel {
    final isWhole = quantity == quantity.roundToDouble();
    final qty = isWhole ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
    return '$qty ${product.unit}';
  }
}