import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminLevel { standard, superAdmin }

class AdminProfile {
  const AdminProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.level,
    required this.permissions,
    required this.active,
    this.createdBy,
  });

  final String uid;
  final String name;
  final String email;
  final AdminLevel level;
  final Set<String> permissions;
  final bool active;
  final String? createdBy;

  bool get isSuperAdmin => level == AdminLevel.superAdmin;

  bool can(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  factory AdminProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final levelValue = (data['level'] as String? ?? 'standard').toLowerCase();
    final rawPermissions = data['permissions'];

    return AdminProfile(
      uid: document.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      level:
          levelValue == 'super' ? AdminLevel.superAdmin : AdminLevel.standard,
      permissions: rawPermissions is Iterable
          ? rawPermissions.whereType<String>().toSet()
          : const <String>{},
      active: data['active_status'] as bool? ?? false,
      createdBy: data['created_by'] as String?,
    );
  }
}

abstract final class AdminPermissions {
  static const customers = 'customers.manage';
  static const farmers = 'farmers.manage';
  static const products = 'products.manage';
  static const categories = 'categories.manage';
  static const orders = 'orders.manage';
  static const reports = 'reports.view';
  static const content = 'content.manage';
  static const markets = 'markets.manage';

  static const allStandard = <String>{
    customers,
    farmers,
    products,
    categories,
    orders,
    reports,
    content,
    markets,
  };
}
