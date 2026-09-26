import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_role.dart';
import '../../presentation/theme/colors/app_colors.dart';

class RoleGuard extends StatefulWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  final Set<UserRole> allowedRoles;
  final Widget child;

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  late final Future<UserRole?> _roleFuture = _loadRole();
  bool _redirectScheduled = false;

  Future<UserRole?> _loadRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!snapshot.exists) return null;

      return userRoleFromStorage(snapshot.data()?['role'] as String?);
    } catch (_) {
      return null;
    }
  }

  void _redirectToLogin() {
    if (_redirectScheduled || !mounted) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GuardLoadingScreen();
        }

        final role = snapshot.data;
        if (role != null && widget.allowedRoles.contains(role)) {
          return widget.child;
        }

        _redirectToLogin();
        return const _GuardLoadingScreen();
      },
    );
  }
}

class _GuardLoadingScreen extends StatelessWidget {
  const _GuardLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.mainGreen),
      ),
    );
  }
}
