import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerAccount {
  const FarmerAccount({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.farmName,
    required this.marketLocation,
    required this.description,
    required this.tagline,
    required this.avatarUrl,
    required this.farmImageUrl,
    required this.rating,
    required this.emailVerified,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String farmName;
  final String marketLocation;
  final String description;
  final String tagline;
  final String avatarUrl;
  final String farmImageUrl;
  final double rating;
  final bool emailVerified;
  final DateTime? createdAt;

  bool get hasAvatar => avatarUrl.trim().isNotEmpty;
  bool get hasFarmImage => farmImageUrl.trim().isNotEmpty;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? '' : parts.first;
  }

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory FarmerAccount.fromDocs(
    DocumentSnapshot<Map<String, dynamic>> userDoc,
    DocumentSnapshot<Map<String, dynamic>> farmerDoc,
  ) {
    final u = userDoc.data() ?? const <String, dynamic>{};
    final f = farmerDoc.data() ?? const <String, dynamic>{};

    String text(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return '';
    }

    double parseRating(Map<String, dynamic> m, List<String> keys) {
      for (final key in keys) {
        final value = m[key];
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    final avatar = text(f, ['avatar_url', 'profile_image_url']).isNotEmpty
        ? text(f, ['avatar_url', 'profile_image_url'])
        : text(u, ['avatar_url', 'photo_url']);

    return FarmerAccount(
      uid: userDoc.id,
      name: text(u, ['name']),
      email: text(u, ['email']),
      phone: text(u, ['phone']),
      farmName: text(f, ['business_name']),
      marketLocation: text(f, ['market_location', 'market_name']),
      description: text(f, ['description']),
      tagline: text(f, ['tagline']),
      avatarUrl: avatar,
      farmImageUrl: text(f, ['farm_image_url', 'farm_photo_url']),
      rating: parseRating(
          f, ['rating', 'average_rating', 'avg_rating', 'rating_value']),
      emailVerified: (u['email_verified'] as bool?) ?? false,
      createdAt: (u['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
