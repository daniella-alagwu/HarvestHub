import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.category,
    required this.pricePerUnit,
    this.farmerName = 'Local Farmer',
    this.marketName = 'Farmers Market',
    this.unit = 'item',
    this.stockQty = 0.0,
    this.distanceMiles = 0.0,
    this.imageUrl,
    this.description = '',
    this.isOrganic = false,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String marketName;
  final String name;
  final String category;
  final double pricePerUnit;

 
  final String unit;
  final double stockQty;
  final double distanceMiles;
  final String? imageUrl;
  final String description;
  final bool isOrganic;

  

  
  String get productId => id;
  String get itemName => name;

  bool get isInStock => stockQty > 0;
  bool get isLowStock => stockQty > 0 && stockQty <= 5;

  String get priceLabel => '\$${pricePerUnit.toStringAsFixed(2)} / $unit';
  String get distanceLabel => '${distanceMiles.toStringAsFixed(1)} mi';


  //parsing firestore docs
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Product(
      id: doc.id,
      farmerId: data['farmer_id'] ?? data['farmerId'] ?? '',
      farmerName: data['farmer_name'] ?? data['farmerName'] ?? 'Local Farmer',
      marketName: data['market_name'] ?? data['marketName'] ?? 'Farmers Market',
      name: data['item_name'] ?? data['name'] ?? data['itemName'] ?? '',
      category: data['category'] ?? 'General',
      pricePerUnit: (data['price_per_unit'] ?? data['pricePerUnit'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? 'item',
      stockQty: (data['stock_qty'] ?? data['stockQty'] ?? 0.0).toDouble(),
      distanceMiles: (data['distance_miles'] ?? data['distanceMiles'] ?? 0.0).toDouble(),
      imageUrl: data['image_url'] ?? data['imageUrl'],
      description: data['description'] ?? '',
      isOrganic: data['is_organic'] ?? data['isOrganic'] ?? false,
    );
  }

  //conversion...
  Map<String, dynamic> toFirestore() {
    return {
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'market_name': marketName,
      'item_name': name,
      'category': category,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'stock_qty': stockQty,
      'distance_miles': distanceMiles,
      'image_url': imageUrl,
      'description': description,
      'is_organic': isOrganic,
    };
  }

  Product copyWith({
    String? farmerName,
    String? marketName,
    String? name,
    String? category,
    double? pricePerUnit,
    String? unit,
    double? stockQty,
    double? distanceMiles,
    String? imageUrl,
    String? description,
    bool? isOrganic,
  }) {
    return Product(
      id: id,
      farmerId: farmerId,
      farmerName: farmerName ?? this.farmerName,
      marketName: marketName ?? this.marketName,
      name: name ?? this.name,
      category: category ?? this.category,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      stockQty: stockQty ?? this.stockQty,
      distanceMiles: distanceMiles ?? this.distanceMiles,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isOrganic: isOrganic ?? this.isOrganic,
    );
  }
}