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

  factory Farmer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Farmer(
      id: doc.id,
      userId: data['User_Id'] ?? data['userId'] ?? '',
      marketId: data['Market_Id'] ?? data['marketId'] ?? '',
      businessName: data['Business_Name'] ?? data['businessName'] ?? '',
      marketName: data['Market_Name'] ?? data['marketName'] ?? 'Local Market',
      rating: (data['Rating'] ?? data['rating'] ?? 0.0).toDouble(),
      distanceMiles: (data['Distance_Miles'] ?? data['distanceMiles'] ?? 0.0).toDouble(),
      description: data['Description'] ?? data['description'] ?? '',
      tagline: data['Tagline'] ?? data['tagline'] ?? '',
      marketDay: data['Market_Day'] ?? data['marketDay'] ?? '',
      followersCount: (data['Followers_Count'] ?? data['followersCount'] ?? 0).toInt(),
      productsCount: (data['Products_Count'] ?? data['productsCount'] ?? 0).toInt(),
      avatarUrl: data['Avatar_Url'] ?? data['avatarUrl'],
    );
  }

  
  Map<String, dynamic> toFirestore() {
    return {
      'User_Id': userId,
      'Market_Id': marketId,
      'Business_Name': businessName,
      'Market_Name': marketName,
      'Rating': rating,
      'Distance_Miles': distanceMiles,
      'Description': description,
      'Tagline': tagline,
      'Market_Day': marketDay,
      'Followers_Count': followersCount,
      'Products_Count': productsCount,
      'Avatar_Url': avatarUrl,
    };
  }
}