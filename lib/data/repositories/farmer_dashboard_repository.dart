import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';

class FarmerDashboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Farmer's doc ID in `farmers` IS the Firebase Auth uid.
  String getFarmerId(String uid) => uid;

  Future<Map<String, String>> getFarmerProfile(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final farmerDoc = await _db.collection('farmers').doc(uid).get();
    return {
      'name': (userDoc.data()?['name'] as String?) ?? '',
      'farmName': (farmerDoc.data()?['business_name'] as String?) ?? '',
    };
  }

  Stream<List<ProductModel>> streamProducts(String farmerId) {
    return _db
        .collection('products')
        .where('farmer_id', isEqualTo: farmerId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
  }

  Stream<List<OrderModel>> streamOrders(String farmerId) {
    return _db
        .collection('orders')
        .where('farmer_id', isEqualTo: farmerId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  Future<void> addProduct({
    required String farmerId,
    required String itemName,
    required String description,
    required double pricePerUnit,
    required int stockQty,
    Uint8List? imageBytes,
  }) async {
    String imageUrl = '';

    if (imageBytes != null) {
      final ref = _storage
          .ref()
          .child('product_images')
          .child(farmerId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      imageUrl = await ref.getDownloadURL();
    }

    await _db.collection('products').add({
      'farmer_id': farmerId,
      'item_name': itemName,
      'description': description,
      'category': '',
      'price_per_unit': pricePerUnit,
      'stock_qty': stockQty,
      'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct({
    required String productId,
    required String farmerId,
    required String itemName,
    required String description,
    required double pricePerUnit,
    required int stockQty,
    Uint8List? newImageBytes,
    String? existingImageUrl,
  }) async {
    String imageUrl = existingImageUrl ?? '';

    if (newImageBytes != null) {
      final ref = _storage
          .ref()
          .child('product_images')
          .child(farmerId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(newImageBytes, SettableMetadata(contentType: 'image/jpeg'));
      imageUrl = await ref.getDownloadURL();
    }

    await _db.collection('products').doc(productId).update({
      'item_name': itemName,
      'description': description,
      'price_per_unit': pricePerUnit,
      'stock_qty': stockQty,
      'image_url': imageUrl,
    });
  }

  Future<void> adjustStock(String productId, int delta) async {
    await _db.collection('products').doc(productId).update({
      'stock_qty': FieldValue.increment(delta),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // ---------------- Notifications ----------------

  Stream<List<NotificationModel>> streamNotifications(String farmerId) {
    return _db
        .collection('notifications')
        .where('farmer_id', isEqualTo: farmerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  /// Creates a notification doc only if one doesn't already exist for this
  /// exact event (deterministic ID), so read/unread state isn't reset every
  /// time the dashboard rebuilds this list.
  Future<void> _ensureNotification({
    required String id,
    required String farmerId,
    required String type,
    required String title,
    required String message,
  }) async {
    final ref = _db.collection('notifications').doc(id);
    final existing = await ref.get();
    if (existing.exists) return;

    await ref.set({
      'farmer_id': farmerId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Call this whenever products/orders are loaded, to keep notifications
  /// in sync with current low-stock items and pending orders.
  Future<void> syncNotifications({
    required String farmerId,
    required List<ProductModel> lowStockProducts,
    required List<OrderModel> pendingOrders,
  }) async {
    for (final p in lowStockProducts) {
      await _ensureNotification(
        id: 'low_stock_${p.productId}',
        farmerId: farmerId,
        type: 'low_stock',
        title: 'Low stock',
        message: '${p.itemName} is running low (${p.stockQty} left).',
      );
    }
    for (final o in pendingOrders) {
      await _ensureNotification(
        id: 'pending_order_${o.orderId}',
        farmerId: farmerId,
        type: 'pending_order',
        title: 'New order pending',
        message: 'Order #${o.orderId.substring(0, o.orderId.length.clamp(0, 6))} needs your attention.',
      );
    }
  }

  Future<void> setNotificationRead(String notificationId, bool isRead) async {
    await _db.collection('notifications').doc(notificationId).update({
      'is_read': isRead,
    });
  }
}