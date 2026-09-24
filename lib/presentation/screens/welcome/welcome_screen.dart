import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import 'package:harvesthub/presentation/screens/auth/login_screen.dart';
import 'package:harvesthub/presentation/screens/auth/role_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
         //image
          Positioned.fill(
            child: Opacity(
              opacity: 0.45, 
              child: Image.asset(
                'assets/images/bg_images/farming.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),

       
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0.15), 
                    AppColors.background.withOpacity(0.10), 
                    AppColors.background.withOpacity(0.45), 
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  //logo
                  Center(
                    child: Image.asset(
                      'assets/splash_screen/logo_full_combined.png',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.softGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.agriculture_rounded,
                              size: 72,
                              color: AppColors.mainGreen,
                            ),
                          ),
                    ),
                  ),

                 
                  Text(
                    'Direct from local farms to your table.\nFresh produce, honest pricing, zero middleman.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(flex: 1),

                
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, RoleSelectionScreen.routeName);
                      },
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                 
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: AppColors.surface.withOpacity(0.90), 
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, LoginScreen.routeName);
                      },
                      child: const Text(
                        'I Already Have an Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}