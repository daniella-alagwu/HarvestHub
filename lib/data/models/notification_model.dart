import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String farmerId;
  final String type; // 'low_stock' or 'pending_order'
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.farmerId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      farmerId: data['farmer_id'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['is_read'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}