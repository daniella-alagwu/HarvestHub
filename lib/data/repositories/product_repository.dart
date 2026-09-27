import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductRepository {
  ProductRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
          firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>>
      get _products =>
          _firestore.collection('products');

  Future<String> addProduct({
    required String farmerId,
    required String itemName,
    required String category,
    required double pricePerUnit,
    required int stockQty,
    String unit = 'item',
    String imageUrl = '',
    String description = '',
    bool isOrganic = false,
    String farmerName = '',
    String marketName = '',
  }) async {
    final doc = await _products.add({
      'farmer_id': farmerId,
      'item_name': itemName,
      'category': category,
      'price_per_unit': pricePerUnit,
      'stock_qty': stockQty,
      'unit': unit,
      'image_url': imageUrl,
      'description': description,
      'is_organic': isOrganic,
      if (farmerName.trim().isNotEmpty)
        'farmer_name': farmerName.trim(),
      if (marketName.trim().isNotEmpty)
        'market_name': marketName.trim(),
      'created_at':
          FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> changes,
  ) =>
      _products.doc(productId).update(changes);

  Future<void> deleteProduct(
    String productId,
  ) =>
      _products.doc(productId).delete();

  Future<void> updateStock(
    String productId,
    int stockQty,
  ) =>
      _products.doc(productId).update({
        'stock_qty': stockQty,
      });

  Future<Product?> fetchById(
    String productId,
  ) async {
    final doc =
        await _products.doc(productId).get();

    if (!doc.exists) {
      return null;
    }

    return Product.fromFirestore(doc);
  }

  Future<List<Product>> fetchAll() async {
    final snapshot =
        await _products.get();

    return snapshot.docs
        .map(Product.fromFirestore)
        .toList();
  }

  Future<List<Product>>
      fetchFreshToday() async {
    final snapshot = await _products
        .where(
          'stock_qty',
          isGreaterThan: 0,
        )
        .limit(4)
        .get();

    return snapshot.docs
        .map(Product.fromFirestore)
        .toList();
  }

  Stream<List<Product>> watchAll() {
    return _products.snapshots().map(
      (snapshot) => snapshot.docs
          .map(Product.fromFirestore)
          .toList(),
    );
  }

  Stream<List<Product>>
      watchProductsForFarmer(
    String farmerId,
  ) {
    return _products
        .where(
          'farmer_id',
          isEqualTo: farmerId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Product.fromFirestore)
              .toList(),
        );
  }

  Stream<List<Product>>
      watchAvailableProducts() {
    return _products
        .where(
          'stock_qty',
          isGreaterThan: 0,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Product.fromFirestore)
              .toList(),
        );
  }

  Stream<List<Product>>
      watchProductsByCategory(
    String category,
  ) {
    return _products
        .where(
          'category',
          isEqualTo: category,
        )
        .where(
          'stock_qty',
          isGreaterThan: 0,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Product.fromFirestore)
              .toList(),
        );
  }
}