import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const RoleSelectionScreen();
        }

        return FutureBuilder<String?>(
          future: AuthRepository().fetchRoleFor(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final role = roleSnapshot.data;
            if (role == null) {
              return const RoleSelectionScreen();
            }

            if (!user.emailVerified) {
              return EmailVerificationScreen(
                email: user.email ?? '',
                role: role,
              );
            }

            return HomeScreen(role: role);
          },
        );
      },
    );
  }
}