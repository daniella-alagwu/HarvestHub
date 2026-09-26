/// Mirrors the `farmers/{farmerId}` Firestore document
/// (see PROJECT_BLUEPRINT.md §4), plus a few display-only fields
/// (tagline, followers, market day) used by the customer UI.
class Farmer {
  const Farmer({
    required this.id,
    required this.userId,
    required this.marketId,
    required this.businessName,
    required this.marketName,
    required this.rating,
    required this.distanceMiles,
    this.description = '',
    this.tagline = '',
    this.marketDay = '',
    this.followersCount = 0,
    this.productsCount = 0,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String marketId;
  final String businessName;
  final String marketName;
  final double rating;
  final double distanceMiles;
  final String description;
  final String tagline;
  final String marketDay;
  final int followersCount;
  final int productsCount;
  final String? avatarUrl;

  String get distanceLabel => '${distanceMiles.toStringAsFixed(1)} mi';
}