import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.customerId,
    this.farmerId,
    this.senderId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String message;
  final String type;
  final String? customerId;
  final String? farmerId;
  final String? senderId;
  final bool isRead;
  final DateTime createdAt;

  bool get isForCustomer => customerId != null && customerId!.isNotEmpty;
  bool get isForFarmer => farmerId != null && farmerId!.isNotEmpty;

  bool belongsToUser(String uid) {
    return (customerId == uid) || (farmerId == uid);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type,
      if (customerId != null) 'customer_id': customerId,
      if (farmerId != null) 'farmer_id': farmerId,
      if (senderId != null) 'sender_id': senderId,
      'is_read': isRead,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  factory AppNotification.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    return AppNotification(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'general',
      customerId: data['customer_id'] as String?,
      farmerId: data['farmer_id'] as String?,
      senderId: data['sender_id'] as String?,
      isRead: (data['is_read'] as bool?) ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? customerId,
    String? farmerId,
    String? senderId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      customerId: customerId ?? this.customerId,
      farmerId: farmerId ?? this.farmerId,
      senderId: senderId ?? this.senderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
