import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../theme/colors/app_colors.dart';
import '../screens/auth/login_screen.dart';
import 'app_page_route.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded, color: AppColors.textPrimary),
      onPressed: () async {
        await AuthRepository().signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          AppPageRoute(page: const LoginScreen()),
          (route) => false,
        );
      },
    );
  }
}