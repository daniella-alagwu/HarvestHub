import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.farmImageUrl,
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
  final String? farmImageUrl;

  String get distanceLabel => '${distanceMiles.toStringAsFixed(1)} mi';

  factory Farmer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String text(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    double number(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is num) return value.toDouble();
      }
      return 0;
    }

    final avatar = text(['avatar_url', 'Avatar_Url', 'avatarUrl']);
    final farmImage =
        text(['farm_image_url', 'farmImageUrl', 'farm_photo_url']);

    return Farmer(
      id: doc.id,
      userId: text(['user_id', 'User_Id', 'userId']),
      marketId: text(['market_id', 'Market_Id', 'marketId']),
      businessName: text(
        ['business_name', 'Business_Name', 'businessName'],
        fallback: 'Local farm',
      ),
      marketName: text(
        ['market_name', 'Market_Name', 'marketName', 'market_location'],
        fallback: 'Local Market',
      ),
      rating: number(['rating', 'Rating']),
      distanceMiles:
          number(['distance_miles', 'Distance_Miles', 'distanceMiles']),
      description: text(['description', 'Description']),
      tagline: text(['tagline', 'Tagline']),
      marketDay: text(['market_day', 'Market_Day', 'marketDay']),
      followersCount:
          number(['followers_count', 'Followers_Count', 'followersCount'])
              .toInt(),
      productsCount:
          number(['products_count', 'Products_Count', 'productsCount']).toInt(),
      avatarUrl: avatar.isEmpty ? null : avatar,
      farmImageUrl: farmImage.isEmpty ? null : farmImage,
    );
  }
}
