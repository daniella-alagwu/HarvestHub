import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/admin_profile.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class AdminRepository {
  AdminRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _admins =>
      _firestore.collection('admins');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _farmers =>
      _firestore.collection('farmers');
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection('audit_logs');
  CollectionReference<Map<String, dynamic>> get _feedback =>
      _firestore.collection('feedback');
  CollectionReference<Map<String, dynamic>> get _markets =>
      _firestore.collection('farmers_market');
  CollectionReference<Map<String, dynamic>> get _content =>
      _firestore.collection('app_content');

  StreamController<Map<String, dynamic>>? _dashboardReportController;
  final _dashboardReportSubscriptions = <StreamSubscription<Object?>>[];
  final _dashboardReportReadySources = <String>{};
  Map<String, dynamic>? _cachedDashboardReport;
  int _dashboardReportGeneration = 0;
  int _dashboardReportRefreshVersion = 0;

  Future<AdminProfile?> getCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final userDocument = await _users.doc(user.uid).get();
    if (userDocument.data()?['role'] != 'admin' ||
        userDocument.data()?['active_status'] == false) {
      return null;
    }
    final document = await _admins.doc(user.uid).get();
    if (!document.exists) return null;
    final admin = AdminProfile.fromDocument(document);
    if (!admin.active) return null;
    return admin;
  }

  Stream<AdminProfile?> watchCurrentAdmin() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _admins.doc(uid).snapshots().asyncMap((document) async {
      if (!document.exists) return null;
      final admin = AdminProfile.fromDocument(document);
      if (!admin.active) return null;
      final user = await _users.doc(uid).get();
      if (user.data()?['role'] != 'admin' ||
          user.data()?['active_status'] == false) {
        return null;
      }
      return admin;
    });
  }

  Stream<List<Map<String, dynamic>>> watchUsers({required String role}) =>
      _users.where('role', isEqualTo: role).snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );

  Stream<List<Map<String, dynamic>>> watchFarmers() =>
      _farmers.snapshots().asyncMap((snapshot) async {
        final results = <Map<String, dynamic>>[];
        for (final farmerDoc in snapshot.docs) {
          final farmer = farmerDoc.data();
          final userId = (farmer['user_id'] as String?) ?? farmerDoc.id;
          final userDoc = await _users.doc(userId).get();
          results.add({
            'id': farmerDoc.id,
            ...farmer,
            'user_id': userId,
            'name': userDoc.data()?['name'] ?? '',
            'email': userDoc.data()?['email'] ?? '',
            'active_status': userDoc.data()?['active_status'] ?? true,
            'approval_status': farmer['approval_status'],
          });
        }
        return results;
      });

  Stream<List<Product>> watchProducts() => _products.snapshots().map(
        (snapshot) => snapshot.docs.map(Product.fromFirestore).toList(),
      );

  Stream<List<Order>> watchOrders() => _orders.snapshots().map(
        (snapshot) => snapshot.docs.map(Order.fromFirestore).toList(),
      );

  Stream<List<Map<String, dynamic>>> watchCategories() =>
      _categories.snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );

  Stream<List<Map<String, dynamic>>> watchFeedback() =>
      _feedback.orderBy('created_at', descending: true).snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );

  Stream<List<Map<String, dynamic>>> watchAuditLogs({int limit = 100}) =>
      _auditLogs
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );

  Stream<List<Map<String, dynamic>>> watchAdmins() =>
      _admins.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchMarkets() =>
      _markets.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

  Stream<Map<String, dynamic>> watchSettings() =>
      _firestore.collection('settings').doc('app').snapshots().map(
            (document) => document.data() ?? const <String, dynamic>{},
          );

  Stream<Map<String, dynamic>> watchDashboardReport() {
    _dashboardReportController ??= StreamController.broadcast(
      onListen: _startDashboardReport,
      onCancel: () => unawaited(_stopDashboardReport()),
    );
    return _dashboardReportController!.stream;
  }

  void _startDashboardReport() {
    final controller = _dashboardReportController;
    if (controller == null || controller.isClosed) return;

    final generation = ++_dashboardReportGeneration;
    _dashboardReportReadySources.clear();
    final cachedReport = _cachedDashboardReport;
    if (cachedReport != null) controller.add(cachedReport);

    _trackDashboardReportSource(
        'orders', _orders.snapshots(), generation);
    _trackDashboardReportSource(
        'farmers', _farmers.snapshots(), generation);
    _trackDashboardReportSource(
        'products', _products.snapshots(), generation);
  }

  void _trackDashboardReportSource<T>(
      String source, Stream<T> stream, int generation) {
    _dashboardReportSubscriptions.add(stream.listen(
      (_) {
        if (generation != _dashboardReportGeneration) return;
        _dashboardReportReadySources.add(source);
        if (_dashboardReportReadySources.length == 3) {
          unawaited(_refreshDashboardReport(generation));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        final controller = _dashboardReportController;
        if (generation == _dashboardReportGeneration &&
            controller != null &&
            controller.hasListener) {
          controller.addError(error, stackTrace);
        }
      },
    ));
  }

  Future<void> _refreshDashboardReport(int generation) async {
    final controller = _dashboardReportController;
    if (controller == null || !controller.hasListener) return;
    final version = ++_dashboardReportRefreshVersion;
    try {
      final report = await getDashboardReport();
      if (generation == _dashboardReportGeneration &&
          version == _dashboardReportRefreshVersion &&
          controller.hasListener) {
        _cachedDashboardReport = report;
        controller.add(report);
      }
    } catch (error, stackTrace) {
      if (generation == _dashboardReportGeneration &&
          version == _dashboardReportRefreshVersion &&
          controller.hasListener) {
        controller.addError(error, stackTrace);
      }
    }
  }

  Future<void> _stopDashboardReport() async {
    ++_dashboardReportGeneration;
    ++_dashboardReportRefreshVersion;
    _dashboardReportReadySources.clear();
    final subscriptions = List<StreamSubscription<Object?>>.of(
        _dashboardReportSubscriptions);
    _dashboardReportSubscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  Stream<Map<String, dynamic>> watchContent(String pageId) =>
      _content.doc(pageId).snapshots().map(
            (document) => document.data() ?? const <String, dynamic>{},
          );

  Future<void> saveContent({
    required String pageId,
    required Map<String, dynamic> values,
  }) async {
    await _content.doc(pageId).set({
      ...values,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': _auth.currentUser?.uid,
    }, SetOptions(merge: true));
    await _log(
      action: 'content.updated',
      targetType: 'app_content',
      targetId: pageId,
      details: values,
    );
  }

  Future<Map<String, dynamic>> getDashboardReport() async {
    final results = await Future.wait([
      _orders.get(),
      _farmers.get(),
      _products.get(),
    ]);
    final orders = results[0].docs;
    final farmers = results[1].docs;
    final products = results[2].docs;

    final revenueByMarket = <String, double>{};
    final ordersByFarmer = <String, int>{};
    var revenue = 0.0;
    for (final doc in orders) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase() ?? '';
      if (status == 'cancelled' || status == 'canceled') continue;
      final amount = _asDouble(data['total_price'] ?? data['total']);
      final market = (data['market_name'] as String?)?.trim();
      final farmerId = data['farmer_id'] as String? ?? '';
      revenue += amount;
      if (market != null && market.isNotEmpty) {
        revenueByMarket.update(market, (total) => total + amount,
            ifAbsent: () => amount);
      }
      if (farmerId.isNotEmpty) {
        ordersByFarmer.update(
            farmerId, (total) => total + 1, ifAbsent: () => 1);
      }
    }

    final farmerNameById = <String, String>{};
    for (final doc in farmers) {
      farmerNameById[doc.id] = doc.data()['business_name'] as String? ?? '';
    }

    final mostActive = ordersByFarmer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_orders': orders.length,
      'revenue': revenue,
      'active_farmers': farmers.length,
      'products': products.length,
      'revenue_by_market': revenueByMarket,
      'most_active_farmers': mostActive
          .take(5)
          .map((entry) => {
                'farmer_id': entry.key,
                'name': (farmerNameById[entry.key]?.trim().isNotEmpty ?? false)
                    ? farmerNameById[entry.key]!.trim()
                    : 'Unnamed farmer',
                'orders': entry.value,
              })
          .toList(),
    };
  }

  Future<void> updateUser({
    required String uid,
    required Map<String, dynamic> changes,
    required String action,
  }) async {
    await _users.doc(uid).update(changes);
    await _log(
        action: action, targetType: 'user', targetId: uid, details: changes);
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).update({'active_status': false});
    await _log(
      action: 'user.disabled',
      targetType: 'user',
      targetId: uid,
      details: {'soft_delete': true},
    );
  }

  Future<void> deleteCustomer(String uid) async {
    await _users.doc(uid).update({'active_status': false});
    await _log(
      action: 'customer.disabled',
      targetType: 'user',
      targetId: uid,
      details: {'soft_delete': true},
    );
  }

  Future<void> editCustomer({
    required String uid,
    required String name,
    required String phone,
    required String address,
  }) async {
    final changes = {
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
    };
    await _users.doc(uid).update(changes);
    await _log(
        action: 'customer.updated',
        targetType: 'user',
        targetId: uid,
        details: changes);
  }

  Future<void> updateFarmer({
    required String farmerId,
    required Map<String, dynamic> changes,
  }) async {
    await _farmers.doc(farmerId).update(changes);
    await _log(
        action: 'farmer.updated',
        targetType: 'farmer',
        targetId: farmerId,
        details: changes);
  }

  Future<void> editFarmer({
    required String farmerId,
    required String userId,
    required String name,
    required String businessName,
    required String marketLocation,
    required String description,
  }) async {
    final batch = _firestore.batch();
    final userChanges = {'name': name.trim()};
    final farmerChanges = {
      'business_name': businessName.trim(),
      'market_location': marketLocation.trim(),
      'description': description.trim(),
    };
    batch.update(_users.doc(userId), userChanges);
    batch.update(_farmers.doc(farmerId), farmerChanges);
    await batch.commit();
    await _log(
        action: 'farmer.updated',
        targetType: 'farmer',
        targetId: farmerId,
        details: {...userChanges, ...farmerChanges});
  }

  Future<void> deleteFarmer({
    required String farmerId,
    required String userId,
  }) async {
    await _users.doc(userId).update({'active_status': false});
    await _log(
      action: 'farmer.disabled',
      targetType: 'farmer',
      targetId: farmerId,
      details: {'user_id': userId, 'soft_delete': true},
    );
  }

  Future<void> setFarmerApproval({
    required String farmerId,
    required String userId,
    required String status,
  }) async {
    if (!const {'pending', 'approved', 'rejected'}.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    final batch = _firestore.batch();
    batch.update(_farmers.doc(farmerId), {
      'approval_status': status,
      'approval_updated_at': FieldValue.serverTimestamp(),
      'approval_updated_by': _auth.currentUser?.uid,
    });
    batch.update(_users.doc(userId), {
      'active_status': status == 'approved',
    });
    await batch.commit();
    await _log(
      action: 'farmer.$status',
      targetType: 'farmer',
      targetId: farmerId,
      details: {'user_id': userId},
    );
  }

  Future<void> saveMarket({
    String? marketId,
    required String name,
    required String address,
    required List<Map<String, dynamic>> pickupSlots,
    required bool active,
  }) async {
    final id = marketId ?? _markets.doc().id;
    await _markets.doc(id).set({
      'market_name': name.trim(),
      'address': address.trim(),
      'pickup_slots': pickupSlots,
      'active_status': active,
      if (marketId == null) 'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _log(
      action: marketId == null ? 'market.created' : 'market.updated',
      targetType: 'market',
      targetId: id,
      details: {'market_name': name.trim()},
    );
  }

  Future<void> deleteMarket(String marketId) async {
    await _markets.doc(marketId).delete();
    await _log(
        action: 'market.deleted', targetType: 'market', targetId: marketId);
  }

  Future<void> updateFeedbackStatus({
    required String feedbackId,
    required String status,
  }) async {
    await _feedback.doc(feedbackId).update({
      'status': status,
      'reviewed_at': FieldValue.serverTimestamp(),
      'reviewed_by': _auth.currentUser?.uid,
    });
    await _log(
      action: 'feedback.reviewed',
      targetType: 'feedback',
      targetId: feedbackId,
      details: {'status': status},
    );
  }

  Future<void> updateProduct({
    required Product product,
    String? name,
    String? category,
    double? price,
    int? stock,
  }) async {
    final changes = <String, dynamic>{
      if (name != null) 'item_name': name,
      if (category != null) 'category': category,
      if (price != null) 'price_per_unit': price,
      if (stock != null) 'stock_qty': stock,
      'updated_at': FieldValue.serverTimestamp(),
    };
    await _products.doc(product.id).update(changes);
    await _log(
        action: 'product.updated',
        targetType: 'product',
        targetId: product.id,
        details: changes);
  }

  Future<String> createProduct({
    required String farmerId,
    required String farmerName,
    required String itemName,
    required String category,
    required double price,
    required int stock,
  }) async {
    final document = await _products.add({
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'item_name': itemName.trim(),
      'category': category.trim(),
      'price_per_unit': price,
      'stock_qty': stock,
      'unit': 'item',
      'image_url': '',
      'description': '',
      'is_organic': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    await _log(
      action: 'product.created',
      targetType: 'product',
      targetId: document.id,
      details: {'item_name': itemName.trim(), 'farmer_id': farmerId},
    );
    return document.id;
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
    await _log(
        action: 'product.deleted', targetType: 'product', targetId: productId);
  }

  Future<void> saveCategory({String? id, required String name}) async {
    final categoryId = id ?? _categories.doc().id;
    await _categories.doc(categoryId).set({
      'name': name.trim(),
      'updated_at': FieldValue.serverTimestamp(),
      if (id == null) 'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _log(
        action: id == null ? 'category.created' : 'category.updated',
        targetType: 'category',
        targetId: categoryId,
        details: {'name': name.trim()});
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categories.doc(categoryId).delete();
    await _log(
        action: 'category.deleted',
        targetType: 'category',
        targetId: categoryId);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _orders.doc(orderId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
    await _log(
        action: 'order.status_changed',
        targetType: 'order',
        targetId: orderId,
        details: {'status': status});
  }

  Future<void> updateSetting(String key, Object value) async {
    await _firestore.collection('settings').doc('app').set({
      key: value,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': _auth.currentUser?.uid,
    }, SetOptions(merge: true));
    await _log(
        action: 'setting.updated',
        targetType: 'setting',
        targetId: key,
        details: {key: value});
  }

  Future<void> _log({
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic> details = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Admin session has expired.');
    final adminDocument = await _admins.doc(user.uid).get();
    final adminData = adminDocument.data() ?? const <String, dynamic>{};
    await _auditLogs.add({
      'admin_id': user.uid,
      'admin_name': adminData['name'] ?? user.displayName ?? user.email,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'timestamp': FieldValue.serverTimestamp(),
      'details': details,
    });
  }

  Future<String> createAdminAccount({
    required String name,
    required String email,
    required String password,
    required Set<String> permissions,
    required bool superAdmin,
  }) async {
    final creator = _auth.currentUser;
    if (creator == null) throw StateError('Super Admin session has expired.');

    final adminApp = await Firebase.initializeApp(
      name: 'admin-provision-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: adminApp);
    String? createdUid;

    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final newUser = credential.user!;
      createdUid = newUser.uid;
      await newUser.updateDisplayName(name.trim());

      final batch = _firestore.batch();
      batch.set(_users.doc(newUser.uid), {
        'name': name.trim(),
        'email': email.trim(),
        'role': 'admin',
        'active_status': true,
        'created_at': FieldValue.serverTimestamp(),
      });
      batch.set(_admins.doc(newUser.uid), {
        'user_id': newUser.uid,
        'name': name.trim(),
        'email': email.trim(),
        'level': superAdmin ? 'super' : 'standard',
        'permissions': superAdmin ? <String>[] : permissions.toList(),
        'active_status': true,
        'created_by': creator.uid,
        'created_at': FieldValue.serverTimestamp(),
      });
      final auditRef = _auditLogs.doc();
      final creatorDocument = await _admins.doc(creator.uid).get();
      final creatorData = creatorDocument.data() ?? const <String, dynamic>{};
      batch.set(auditRef, {
        'admin_id': creator.uid,
        'admin_name':
            creatorData['name'] ?? creator.displayName ?? creator.email,
        'action': 'admin.created',
        'target_type': 'admin',
        'target_id': newUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'details': {'level': superAdmin ? 'super' : 'standard'},
      });
      await batch.commit();
      return newUser.uid;
    } catch (_) {
      if (createdUid != null) {
        try {
          await secondaryAuth.currentUser?.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
      try {
        await adminApp.delete();
      } catch (_) {}
    }
  }

  Future<void> updateAdmin({
    required String uid,
    required Map<String, dynamic> changes,
  }) async {
    await _admins.doc(uid).update(changes);
    final userChanges = <String, dynamic>{};
    if (changes['active_status'] is bool) {
      userChanges['active_status'] = changes['active_status'];
    }
    if (userChanges.isNotEmpty) await _users.doc(uid).update(userChanges);
    await _log(
        action: 'admin.updated',
        targetType: 'admin',
        targetId: uid,
        details: changes);
  }

  Future<void> editAdminPermissions({
    required String uid,
    required Set<String> permissions,
  }) async {
    await _admins.doc(uid).update({'permissions': permissions.toList()});
    await _log(
      action: 'admin.permissions_changed',
      targetType: 'admin',
      targetId: uid,
      details: {'permissions': permissions.toList()},
    );
  }

  Future<void> deleteAdminAccount(String uid) async {
    await _admins.doc(uid).update({'active_status': false});
    await _users.doc(uid).update({'active_status': false});
    await _log(action: 'admin.disabled', targetType: 'admin', targetId: uid);
  }

  double _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}
