import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Future<String> addProduct({
    required String farmerId,
    required String itemName,
    required String category,
    required double pricePerUnit,
    required int stockQty,
    String imageUrl = '',
  }) async {
    final doc = await _products.add({
      'farmer_id': farmerId,
      'item_name': itemName,
      'category': category,
      'price_per_unit': pricePerUnit,
      'stock_qty': stockQty,
      'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> changes) {
    return _products.doc(productId).update(changes);
  }

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }

  Future<void> updateStock(String productId, int stockQty) {
    return _products.doc(productId).update({'stock_qty': stockQty});
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProduct(
      String productId) {
    return _products.doc(productId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProductsForFarmer(
      String farmerId) {
    return _products.where('farmer_id', isEqualTo: farmerId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAvailableProducts() {
    return _products.where('stock_qty', isGreaterThan: 0).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProductsByCategory(
      String category) {
    return _products
        .where('category', isEqualTo: category)
        .where('stock_qty', isGreaterThan: 0)
        .snapshots();
  }
}