import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  // ---------------------------------------------------------------------------
  // WRITE & MANAGEMENT OPERATIONS (Farmer Management)
  // ---------------------------------------------------------------------------

  /// Adds a new product document to Firestore
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
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Updates existing product fields in Firestore
  Future<void> updateProduct(String productId, Map<String, dynamic> changes) {
    return _products.doc(productId).update(changes);
  }

  /// Removes a product from the Firestore catalog
  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }

  /// Directly updates stock quantity for rapid inventory adjustments
  Future<void> updateStock(String productId, int stockQty) {
    return _products.doc(productId).update({'stock_qty': stockQty});
  }

  // ---------------------------------------------------------------------------
  // READ OPERATIONS & CUSTOMER UI FETCHERS
  // ---------------------------------------------------------------------------

  /// Fetches a single product by ID from Firestore, falling back to mock data
  Future<Product?> fetchById(String productId) async {
    try {
      final doc = await _products.doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
    } catch (_) {
      // Fallback on network or Firestore error
    }

    try {
      return _mockProducts.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Fetches all available products from Firestore, falling back to mock catalog
  Future<List<Product>> fetchAll() async {
    try {
      final snapshot = await _products.get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      }
    } catch (_) {
      // Fallback to mock data if offline or collection empty
    }
    return List.unmodifiable(_mockProducts);
  }

  /// Fetches featured "Fresh Today" items
  Future<List<Product>> fetchFreshToday() async {
    try {
      final snapshot = await _products
          .where('stock_qty', isGreaterThan: 0)
          .limit(4)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      }
    } catch (_) {
      // Fallback to mock data
    }
    return _mockProducts.take(4).toList();
  }

  /// Extract distinct category list
  List<String> get categories =>
      _mockProducts.map((p) => p.category).toSet().toList()..sort();

  // ---------------------------------------------------------------------------
  // REAL-TIME FIRESTORE STREAMS
  // ---------------------------------------------------------------------------

  /// Real-time stream of products listed by a specific farmer
  Stream<List<Product>> watchProductsForFarmer(String farmerId) {
    return _products
        .where('farmer_id', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  /// Real-time stream of all in-stock products
  Stream<List<Product>> watchAvailableProducts() {
    return _products
        .where('stock_qty', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  /// Real-time stream of in-stock products filtered by category
  Stream<List<Product>> watchProductsByCategory(String category) {
    return _products
        .where('category', isEqualTo: category)
        .where('stock_qty', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // ---------------------------------------------------------------------------
  // MOCK CATALOG (Fallback / Seed Data)
  // ---------------------------------------------------------------------------

  static final List<Product> _mockProducts = [
    const Product(
      id: 'p_heirloom_tomatoes',
      farmerId: 'f_maple_row',
      farmerName: 'Maple Row Farm',
      marketName: 'PSU Farmers Market',
      name: 'Heirloom Tomatoes',
      category: 'Vegetables',
      pricePerUnit: 4.80,
      unit: 'lb',
      stockQty: 32,
      distanceMiles: 2.4,
      isOrganic: true,
      description: 'Sweet, sun-ripened tomatoes picked this morning. A '
          'colorful mix perfect for salads, toast, and sauces.',
    ),
    const Product(
      id: 'p_garden_kale',
      farmerId: 'f_maple_row',
      farmerName: 'Maple Row Farm',
      marketName: 'PSU Farmers Market',
      name: 'Garden Kale',
      category: 'Vegetables',
      pricePerUnit: 3.25,
      unit: 'bunch',
      stockQty: 14,
      distanceMiles: 2.4,
      description: 'Crisp, dark leafy kale — great for sautéing, salads, '
          'or blending into a morning smoothie.',
    ),
    const Product(
      id: 'p_vine_tomatoes',
      farmerId: 'f_riverbend',
      farmerName: 'Riverbend Organics',
      marketName: 'PSU Farmers Market',
      name: 'Vine Tomatoes',
      category: 'Vegetables',
      pricePerUnit: 4.20,
      unit: 'lb',
      stockQty: 20,
      distanceMiles: 1.8,
      isOrganic: true,
      description: 'Ripened on the vine for full flavor, harvested the '
          'same day they reach the market.',
    ),
    const Product(
      id: 'p_cherry_tomato_pint',
      farmerId: 'f_sunrise_acres',
      farmerName: 'Sunrise Acres',
      marketName: 'PSU Farmers Market',
      name: 'Cherry Tomato Pint',
      category: 'Vegetables',
      pricePerUnit: 5.50,
      unit: 'pint',
      stockQty: 16,
      distanceMiles: 3.1,
      description: 'Bite-sized and sweet — perfect for snacking, salads, '
          'or roasting whole.',
    ),
    const Product(
      id: 'p_roma_tomatoes',
      farmerId: 'f_maple_row',
      farmerName: 'Maple Row Farm',
      marketName: 'PSU Farmers Market',
      name: 'Roma Tomatoes',
      category: 'Vegetables',
      pricePerUnit: 3.90,
      unit: 'lb',
      stockQty: 25,
      distanceMiles: 4.6,
      description: 'Firm and meaty with fewer seeds — ideal for sauces, '
          'pastes, and slow roasting.',
    ),
    const Product(
      id: 'p_free_range_eggs',
      farmerId: 'f_maple_row',
      farmerName: 'Maple Row Farm',
      marketName: 'PSU Farmers Market',
      name: 'Free-range Eggs',
      category: 'Dairy',
      pricePerUnit: 6.50,
      unit: 'dozen',
      stockQty: 4,
      distanceMiles: 2.4,
      description: 'Pasture-raised hens, collected fresh — rich, golden '
          'yolks with no additives.',
    ),
    const Product(
      id: 'p_sweet_basil',
      farmerId: 'f_maple_row',
      farmerName: 'Maple Row Farm',
      marketName: 'PSU Farmers Market',
      name: 'Sweet Basil',
      category: 'Herbs',
      pricePerUnit: 2.75,
      unit: 'bunch',
      stockQty: 0,
      distanceMiles: 2.4,
      description: 'Fragrant, tender leaves — a pesto and caprese '
          'staple. Currently out of stock.',
    ),
    const Product(
      id: 'p_garden_kale_bunch2',
      farmerId: 'f_riverbend',
      farmerName: 'Riverbend Organics',
      marketName: 'PSU Farmers Market',
      name: 'Rainbow Chard',
      category: 'Vegetables',
      pricePerUnit: 3.60,
      unit: 'bunch',
      stockQty: 9,
      distanceMiles: 1.8,
      isOrganic: true,
      description: 'Vibrant stems and tender leaves — mild, earthy '
          'flavor good raw or cooked.',
    ),
  ];
}