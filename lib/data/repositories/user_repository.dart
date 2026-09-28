import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_profile.dart';

class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  Stream<UserProfile?> watchCurrentUserProfile() {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserProfile.fromDoc(doc) : null,
        );
  }

  Future<void> updatePickupLocation(String location) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'pickup_location': location.trim(),
    });
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
    required String pickupLocation,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to update your profile.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'pickup_location': pickupLocation.trim(),
    });

    try {
      await user.updateDisplayName(name.trim());
    } catch (_) {
      // Firestore remains the source of truth.
    }
  }

  // Upload customer profile picture.
  Future<String> uploadProfilePicture(File imageFile) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    final storageRef = _storage
        .ref()
        .child('profile_pictures')
        .child('${user.uid}.jpg');

    await storageRef.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    final downloadUrl = await storageRef.getDownloadURL();

    // Save to Firebase Auth.
    await user.updatePhotoURL(downloadUrl);

    // Save to Firestore.
    await _firestore.collection('users').doc(user.uid).set(
      {
        'photo_url': downloadUrl,
      },
      SetOptions(merge: true),
    );

    await user.reload();

    return downloadUrl;
  }
}