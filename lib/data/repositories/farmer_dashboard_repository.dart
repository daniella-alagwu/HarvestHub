import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/cloudinary_service.dart';
import '../models/farmer_account.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';

class FarmerDashboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  String getFarmerId(String uid) => uid;

  Future<Map<String, String>> getFarmerProfile(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final farmerDoc = await _db.collection('farmers').doc(uid).get();

    return {
      'name': (userDoc.data()?['name'] as String?) ?? '',
      'farmName': (farmerDoc.data()?['business_name'] as String?) ?? '',
    };
  }

  Stream<FarmerAccount> watchFarmerAccount(String uid) {
    late final StreamController<FarmerAccount> controller;
    DocumentSnapshot<Map<String, dynamic>>? userSnap;
    DocumentSnapshot<Map<String, dynamic>>? farmerSnap;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? farmerSub;

    void emit() {
      final u = userSnap;
      final f = farmerSnap;
      if (u == null || f == null) return;
      controller.add(FarmerAccount.fromDocs(u, f));
    }

    controller = StreamController<FarmerAccount>(
      onListen: () {
        userSub = _db.collection('users').doc(uid).snapshots().listen(
          (snap) {
            userSnap = snap;
            emit();
          },
          onError: controller.addError,
        );
        farmerSub = _db.collection('farmers').doc(uid).snapshots().listen(
          (snap) {
            farmerSnap = snap;
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await userSub?.cancel();
        await farmerSub?.cancel();
      },
    );
    return controller.stream;
  }

  Future<String> uploadProfileImage(Uint8List bytes, {required String name}) {
    return _cloudinary.uploadImage(bytes, filename: name);
  }

  Future<void> updateFarmerProfile({
    required String uid,
    required String name,
    required String phone,
    required String farmName,
    required String marketLocation,
    required String description,
    required String tagline,
    Uint8List? newAvatarBytes,
    Uint8List? newFarmImageBytes,
  }) async {
    String? avatarUrl;
    String? farmImageUrl;

    if (newAvatarBytes != null) {
      avatarUrl = await _cloudinary.uploadImage(
        newAvatarBytes,
        filename: 'profile_$uid.jpg',
      );
    }
    if (newFarmImageBytes != null) {
      farmImageUrl = await _cloudinary.uploadImage(
        newFarmImageBytes,
        filename: 'farm_$uid.jpg',
      );
    }

    final userUpdate = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    final farmerUpdate = <String, dynamic>{
      'business_name': farmName.trim(),
      'market_location': marketLocation.trim(),
      'description': description.trim(),
      'tagline': tagline.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (farmImageUrl != null) 'farm_image_url': farmImageUrl,
    };

    await _db
        .collection('users')
        .doc(uid)
        .set(userUpdate, SetOptions(merge: true));
    await _db
        .collection('farmers')
        .doc(uid)
        .set(farmerUpdate, SetOptions(merge: true));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        await user.updateDisplayName(name.trim());
        if (avatarUrl != null) await user.updatePhotoURL(avatarUrl);
      }
    } catch (_) {
    }
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
    required String category,
    required String description,
    required double pricePerUnit,
    required int stockQty,
    Uint8List? imageBytes,
  }) async {
    String imageUrl = '';

    if (imageBytes != null) {
      imageUrl = await _cloudinary.uploadImage(imageBytes);
    }

    await _db.collection('products').add({
      'farmer_id': farmerId,
      'item_name': itemName,
      'description': description,
      'category': category,
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
    required String category,
    required String description,
    required double pricePerUnit,
    required int stockQty,
    Uint8List? newImageBytes,
    String? existingImageUrl,
  }) async {
    String imageUrl = existingImageUrl ?? '';

    if (newImageBytes != null) {
      imageUrl = await _cloudinary.uploadImage(newImageBytes);
    }

    await _db.collection('products').doc(productId).update({
      'item_name': itemName,
      'description': description,
      'category': category,
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

  Stream<List<NotificationModel>> streamNotifications(String farmerId) {
    return _db
        .collection('notifications')
        .where('farmer_id', isEqualTo: farmerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

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
          message:
              '${product.itemName} is down to just ${product.stockQty} left — might be time to top it up!',
        );
      } else if (product.stockQty <= 10) {
        await _ensureNotification(
          id: 'stock_10_${product.productId}',
          farmerId: farmerId,
          type: 'low_stock',
          title: 'Stock update',
          message:
              'Heads up! ${product.itemName} has ${product.stockQty} left in stock.',
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

  Future<void> syncNotifications({
    required String farmerId,
    required List<ProductModel> allProducts,
    required List<OrderModel> pendingOrders,
  }) async {
    await _syncStockNotifications(farmerId: farmerId, products: allProducts);
    await _syncOrderNotifications(
        farmerId: farmerId, pendingOrders: pendingOrders);
  }

  Future<void> setNotificationRead(String notificationId, bool isRead) async {
    await _db.collection('notifications').doc(notificationId).update({
      'is_read': isRead,
    });
  }
}