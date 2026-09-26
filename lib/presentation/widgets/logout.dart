import 'package:flutter/material.dart';
import 'package:harvesthub/presentation/screens/splash/splash_screen.dart';
import '../../data/repositories/auth_repository.dart';
import '../theme/colors/app_colors.dart';
import 'app_page_route.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _isSigningOut = false;

  Future<void> _handleLogout() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await AuthRepository().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(page: const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not log out. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSigningOut) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.textPrimary),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.logout_rounded, color: AppColors.textPrimary),
      onPressed: _handleLogout,
    );
  }
}
