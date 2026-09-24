import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Image.asset(
                'assets/splash_screen/logo_full_combined.png',
                width: 210,
              ),
              const SizedBox(height: 28),

              Text(
                'Fresh from Farms,\nDirect to You',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLarge.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 10),
              Text(
                'Browse fresh produce from local farmers, compare prices, '
                'and order straight from the source.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),

              const SizedBox(height: 32),
              const _FeatureRow(),

              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                   
                    debugPrint('Get Started tapped → role selection');
                  },
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  
                  debugPrint('Login tapped → login screen');
                },
                child: Text(
                  'I already have an account',
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  static const _features = [
    (Icons.eco_outlined, 'Fresh &\nHealthy'),
    (Icons.location_on_outlined, 'Locally\nSourced'),
    (Icons.groups_outlined, 'Support\nFarmers'),
    (Icons.shopping_basket_outlined, 'Easy\nOrdering'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _features
          .map(
            (f) => Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.softGreen,
                    child: Icon(f.$1, color: AppColors.mainGreen, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    f.$2,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
