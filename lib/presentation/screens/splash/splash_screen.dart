import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../welcome/welcome_screen.dart';
import 'animated_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  void _goToWelcome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
              if (context.mounted) _goToWelcome(context);
            });
          },
        ),
      ),
    );
  }
}