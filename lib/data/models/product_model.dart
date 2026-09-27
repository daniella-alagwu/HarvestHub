import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.farmerId,
    required this.itemName,
    required this.pricePerUnit,
    required this.stockQty,
    this.category,
    this.imageUrl,
    this.unit = 'item',
    this.description = '',
    this.isOrganic = false,
    this.farmerName = '',
    this.marketName = '',
    this.distanceMiles = 0,
  });

  final String id;
  final String farmerId;
  final String itemName;
  final double pricePerUnit;
  final int stockQty;
  final String? category;
  final String? imageUrl;
  final String unit;
  final String description;
  final bool isOrganic;
  final String farmerName;
  final String marketName;
  final double distanceMiles;

 
  String get productId => id;
  String get name => itemName;
  double get price => pricePerUnit;
  int get quantity => stockQty;

  String get priceLabel =>
      '\$${pricePerUnit.toStringAsFixed(2)} / $unit';

  bool get isInStock => stockQty > 0;

  String get distanceLabel => distanceMiles > 0
      ? '${distanceMiles.toStringAsFixed(1)} mi'
      : 'Local';

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};

    return Product(
      id: doc.id,
      farmerId: _asString(
        data['farmer_id'] ?? data['farmerId'],
      ),
      itemName: _asString(
        data['item_name'] ?? data['itemName'],
      ),
      pricePerUnit: _asDouble(
        data['price_per_unit'] ??
            data['pricePerUnit'] ??
            data['price'],
      ),
      stockQty: _asInt(
        data['stock_qty'] ??
            data['stockQty'] ??
            data['quantity'],
      ),
      category: _nullableString(data['category']),
      imageUrl: _nullableString(
        data['image_url'] ?? data['imageUrl'],
      ),
      unit: _asString(
        data['unit'],
        fallback: 'item',
      ),
      description: _asString(data['description']),
      isOrganic: _asBool(
        data['is_organic'] ?? data['isOrganic'],
      ),
      farmerName: _asString(
        data['farmer_name'] ?? data['farmerName'],
      ),
      marketName: _asString(
        data['market_name'] ?? data['marketName'],
      ),
      distanceMiles: _asDouble(
        data['distance_miles'] ?? data['distanceMiles'],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
        'farmer_name': farmerName,
      if (marketName.trim().isNotEmpty)
        'market_name': marketName,
      if (distanceMiles > 0)
        'distance_miles': distanceMiles,
    };
  }

  Product copyWith({
    String? farmerName,
    String? marketName,
    double? distanceMiles,
    String? description,
    String? category,
    String? imageUrl,
    String? unit,
    bool? isOrganic,
    int? stockQty,
    double? pricePerUnit,
  }) {
    return Product(
      id: id,
      farmerId: farmerId,
      itemName: itemName,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      stockQty: stockQty ?? this.stockQty,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      isOrganic: isOrganic ?? this.isOrganic,
      farmerName: farmerName ?? this.farmerName,
      marketName: marketName ?? this.marketName,
      distanceMiles: distanceMiles ?? this.distanceMiles,
    );
  }

  static String _asString(
    Object? value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;

    final string = value.toString();
    return string.isEmpty ? null : string;
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;

    return value?.toString().toLowerCase() == 'true';
  }
}

typedef ProductModel = Product;