import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/logout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.role});

  final String? role;

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == 'farmer' ? 'Farmer' : 'Customer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [LogoutButton()],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.softGreen,
                  child: const Icon(Icons.eco_outlined,
                      color: AppColors.mainGreen, size: 28),
                ),
                const SizedBox(height: 20),
                Text("You're in!",
                    style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  "Signed in as $roleLabel. The $roleLabel dashboard isn't built yet — this is a placeholder landing page.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
