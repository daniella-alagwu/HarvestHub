import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../theme/colors/app_colors.dart';
import 'role_router.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState
    extends State<AuthGate> {
  String? _cachedUid;
  Future<String?>? _roleFuture;

  Future<String?> _roleFutureFor(
    String uid,
  ) {
    if (_cachedUid != uid) {
      _cachedUid = uid;
      _roleFuture =
          AuthRepository()
              .fetchRoleFor(uid);
    }

    return _roleFuture!;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance
              .authStateChanges(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot
                .connectionState ==
            ConnectionState.waiting) {
          return const _AuthLoadingView();
        }

        final user =
            snapshot.data;

        if (user == null) {
          return const RoleSelectionScreen();
        }

        return FutureBuilder<String?>(
          future:
              _roleFutureFor(
            user.uid,
          ),
          builder: (
            context,
            roleSnapshot,
          ) {
            if (roleSnapshot
                    .connectionState ==
                ConnectionState.waiting) {
              return const _AuthLoadingView();
            }

            final role =
                roleSnapshot.data;

            if (role == null) {
              return const RoleSelectionScreen();
            }

            if (!user.emailVerified &&
                roleNeedsEmailVerification(
                  role,
                )) {
              return EmailVerificationScreen(
                email:
                    user.email ?? '',
                role: role,
              );
            }

            return screenForRole(
              role,
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingView
    extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Scaffold(
      backgroundColor:
          AppColors.background,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child:
              CircularProgressIndicator(
            strokeWidth: 2.5,
            color:
                AppColors.mainGreen,
          ),
        ),
      ),
    );
  }
}