import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../widgets/auth_gate.dart';
import '../welcome/welcome_screen.dart';
import 'animated_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  Future<void> _goNext(BuildContext context) async {
    User? user;
    try {
      // Wait for Firebase to restore any saved session before deciding.
      user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      user = null;
    }

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        // Signed out: Welcome page (tractor). Signed in: AuthGate routes by role.
        builder: (_) => user == null ? const WelcomeScreen() : const AuthGate(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedLogo(
          size: 260,
          onAnimationComplete: () {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) _goNext(context);
            });
          },
        ),
      ),
    );
  }
}