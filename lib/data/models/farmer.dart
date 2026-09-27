import 'package:cloud_firestore/cloud_firestore.dart';

class Farmer {
  const Farmer({
    required this.id,
    required this.userId,
    required this.businessName,
    this.marketLocation,
    this.description,
    this.rating = 0,
  });

  final String id;
  final String userId;
  final String businessName;
  final String? marketLocation;
  final String? description;
  final double rating;

  factory Farmer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Farmer(
      id: doc.id,
      userId: (data['user_id'] as String?) ?? '',
      businessName: (data['business_name'] as String?) ?? 'Unnamed farm',
      marketLocation: data['market_location'] as String?,
      description: data['description'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}