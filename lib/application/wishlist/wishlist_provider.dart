import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Keeps customer favorites and followed farmers synced with Firestore.
class WishlistProvider extends ChangeNotifier {
  WishlistProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _authSubscription = _auth.authStateChanges().listen(_watchUser);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _wishlistSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _followsSubscription;
  String? _userId;
  final Set<String> _wishlistedProductIds = {};
  final Set<String> _followedFarmerIds = {};

  bool isWishlisted(String productId) => _wishlistedProductIds.contains(productId);
  bool isFollowing(String farmerId) => _followedFarmerIds.contains(farmerId);
  int get wishlistCount => _wishlistedProductIds.length;

  void _watchUser(User? user) {
    _wishlistSubscription?.cancel();
    _followsSubscription?.cancel();
    _wishlistedProductIds.clear();
    _followedFarmerIds.clear();
    _userId = user?.uid;
    if (user != null) {
      _wishlistSubscription = _firestore
          .collection('wishlists').doc(user.uid).collection('items').snapshots()
          .listen((snapshot) {
        _wishlistedProductIds
          ..clear()
          ..addAll(snapshot.docs.map((doc) => doc.id));
        notifyListeners();
      });
      _followsSubscription = _firestore
          .collection('follows').doc(user.uid).collection('farmers').snapshots()
          .listen((snapshot) {
        _followedFarmerIds
          ..clear()
          ..addAll(snapshot.docs.map((doc) => doc.id));
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> toggleWishlist(String productId) async {
    final uid = _userId;
    if (uid == null) return;
    final ref = _firestore.collection('wishlists').doc(uid).collection('items').doc(productId);
    if (_wishlistedProductIds.contains(productId)) {
      await ref.delete();
    } else {
      await ref.set({'created_at': FieldValue.serverTimestamp()});
    }
  }

  Future<void> toggleFollow(String farmerId) async {
    final uid = _userId;
    if (uid == null) return;
    final ref = _firestore.collection('follows').doc(uid).collection('farmers').doc(farmerId);
    if (_followedFarmerIds.contains(farmerId)) {
      await ref.delete();
    } else {
      await ref.set({'created_at': FieldValue.serverTimestamp()});
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _wishlistSubscription?.cancel();
    _followsSubscription?.cancel();
    super.dispose();
  }
}
