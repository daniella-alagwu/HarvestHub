import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.pickupLocation,
    this.emailVerified = false,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? pickupLocation;
  final bool emailVerified;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: (data['role'] as String?) ?? 'customer',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      pickupLocation: data['pickup_location'] as String?,
      emailVerified: (data['email_verified'] as bool?) ?? false,
    );
  }
}