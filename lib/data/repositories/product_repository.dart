import '../models/product_model.dart';

/// Reads from a local mock catalog today. Field names mirror the
/// `products/{productId}` Firestore schema in PROJECT_BLUEPRINT.md §4,
/// so swapping `_mockProducts` for a `cloud_firestore` query later is a
/// drop-in change — screens/providers only ever see [Product].
class ProductRepository {
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

  Future<List<Product>> fetchAll() async {
    return List.unmodifiable(_mockProducts);
  }

  Future<List<Product>> fetchFreshToday() async {
    return _mockProducts.take(4).toList();
  }

  Future<Product?> fetchById(String id) async {
    for (final product in _mockProducts) {
      if (product.id == id) return product;
    }
    return null;
  }

  List<String> get categories =>
      _mockProducts.map((p) => p.category).toSet().toList()..sort();
}