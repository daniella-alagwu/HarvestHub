import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String farmerId;
  final String itemName;
  final String description;
  final String category;
  final double pricePerUnit;
  final int stockQty;
  final String imageUrl;

  ProductModel({
    required this.productId,
    required this.farmerId,
    required this.itemName,
    required this.description,
    required this.category,
    required this.pricePerUnit,
    required this.stockQty,
    required this.imageUrl,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: doc.id,
      farmerId: data['farmer_id'] ?? '',
      itemName: data['item_name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      pricePerUnit: (data['price_per_unit'] ?? 0).toDouble(),
      stockQty: (data['stock_qty'] ?? 0).toInt(),
      imageUrl: data['image_url'] ?? '',
    );
  }
}