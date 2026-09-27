import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerModel {
  final String farmerId;
  final String userId;
  final String marketId;
  final String businessName;
  final String description;
  final double rating;

  FarmerModel({
    required this.farmerId,
    required this.userId,
    required this.marketId,
    required this.businessName,
    required this.description,
    required this.rating,
  });

  factory FarmerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FarmerModel(
      farmerId: doc.id,
      userId: data['User_Id'] ?? '',
      marketId: data['Market_Id'] ?? '',
      businessName: data['Business_Name'] ?? '',
      description: data['Description'] ?? '',
      rating: (data['Rating'] ?? 0).toDouble(),
    );
  }
}