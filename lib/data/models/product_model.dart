/// Mirrors the `products/{productId}` Firestore document
/// (see PROJECT_BLUEPRINT.md §4).
class Product {
  const Product({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.marketName,
    required this.name,
    required this.category,
    required this.pricePerUnit,
    required this.unit,
    required this.stockQty,
    required this.distanceMiles,
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

  /// e.g. "lb", "bunch", "dozen", "pint"
  final String unit;
  final double stockQty;
  final double distanceMiles;
  final String? imageUrl;
  final String description;
  final bool isOrganic;

  bool get isInStock => stockQty > 0;

  bool get isLowStock => stockQty > 0 && stockQty <= 5;

  String get priceLabel => '\$${pricePerUnit.toStringAsFixed(2)} / $unit';

  String get distanceLabel => '${distanceMiles.toStringAsFixed(1)} mi';

  Product copyWith({double? stockQty}) {
    return Product(
      id: id,
      farmerId: farmerId,
      farmerName: farmerName,
      marketName: marketName,
      name: name,
      category: category,
      pricePerUnit: pricePerUnit,
      unit: unit,
      stockQty: stockQty ?? this.stockQty,
      distanceMiles: distanceMiles,
      imageUrl: imageUrl,
      description: description,
      isOrganic: isOrganic,
    );
  }
}