import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.farmerId,
    required this.itemName,
    required this.category,
    required this.pricePerUnit,
    required this.stockQty,
    this.imageUrl,
  });

  final String id;
  final String farmerId;
  final String itemName;
  final String category;
  final double pricePerUnit;
  final int stockQty;
  final String? imageUrl;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Product(
      id: doc.id,
      farmerId: (data['farmer_id'] as String?) ?? '',
      itemName: (data['item_name'] as String?) ?? 'Unnamed product',
      category: (data['category'] as String?) ?? '',
      pricePerUnit: (data['price_per_unit'] as num?)?.toDouble() ?? 0,
      stockQty: (data['stock_qty'] as num?)?.toInt() ?? 0,
      imageUrl: data['image_url'] as String?,
    );
  }


  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return itemName.toLowerCase().contains(q) || category.toLowerCase().contains(q);
  }
}