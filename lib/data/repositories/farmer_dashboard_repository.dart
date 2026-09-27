import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';

class FarmerDashboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
        .map((snap) => snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
  }

  Stream<List<OrderModel>> streamOrders(String farmerId) {
    return _db
        .collection('orders')
        .where('farmer_id', isEqualTo: farmerId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
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

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  // NOTIFICATIONS

  Stream<List<NotificationModel>> streamNotifications(String farmerId) {
    return _db
        .collection('notifications')
        .where('farmer_id', isEqualTo: farmerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
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

  /// Checks every product's stock against three thresholds (10, 5, out of
  /// stock) and creates a friendly notification the first time each
  /// threshold is hit. Each threshold has its own deterministic ID per
  /// product, so a farmer only gets one notification per threshold crossed
  /// — restocking above 10 and dropping again would re-trigger it, since
  /// that's a genuinely new low-stock event.
  Future<void> _syncStockNotifications({
    required String farmerId,
    required List<ProductModel> products,
  }) async {
    for (final product in products) {
      if (product.stockQty <= 0) {
        await _ensureNotification(
          id: 'stock_out_${product.productId}',
          farmerId: farmerId,
          type: 'low_stock',
          title: 'Out of stock',
          message:
              '${product.itemName} is completely out of stock. Restock it soon so customers don\'t miss out!',
        );
      } else if (product.stockQty <= 5) {
        await _ensureNotification(
          id: 'stock_5_${product.productId}',
          farmerId: farmerId,
          type: 'low_stock',
          title: 'Running low',
          message: '${product.itemName} is down to just ${product.stockQty} left — might be time to top it up!',
        );
      } else if (product.stockQty <= 10) {
        await _ensureNotification(
          id: 'stock_10_${product.productId}',
          farmerId: farmerId,
          type: 'low_stock',
          title: 'Stock update',
          message: 'Heads up! ${product.itemName} has ${product.stockQty} left in stock.',
        );
      }
    }
  }

  Future<void> _syncOrderNotifications({
    required String farmerId,
    required List<OrderModel> pendingOrders,
  }) async {
    for (final order in pendingOrders) {
      await _ensureNotification(
        id: 'pending_order_${order.orderId}',
        farmerId: farmerId,
        type: 'pending_order',
        title: 'New order pending',
        message:
            'Order #${order.orderId.substring(0, order.orderId.length.clamp(0, 6))} needs your attention.',
      );
    }
  }

  /// Call this on every dashboard load with the FULL product list (not just
  /// already-low-stock ones) so all three stock thresholds get checked.
  Future<void> syncNotifications({
    required String farmerId,
    required List<ProductModel> allProducts,
    required List<OrderModel> pendingOrders,
  }) async {
    await _syncStockNotifications(farmerId: farmerId, products: allProducts);
    await _syncOrderNotifications(farmerId: farmerId, pendingOrders: pendingOrders);
  }

  Future<void> setNotificationRead(String notificationId, bool isRead) async {
    await _db.collection('notifications').doc(notificationId).update({
      'is_read': isRead,
    });
  }
}