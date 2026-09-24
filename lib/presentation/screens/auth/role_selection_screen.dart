import 'package:flutter/material.dart';
import '../../../data/models/user_role.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_page_route.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  static const routeName = '/role-selection';

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.customer;

  Color get _accent =>
      _selectedRole == UserRole.customer ? AppColors.mainGreen : AppColors.autumnRust;

  void _continue() {
    Navigator.of(context).push(
      AppPageRoute(page: RegisterScreen(role: _selectedRole)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP 1 OF 2',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.wheatGold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'How will you use HarvestHub?',
                style: AppTextStyles.headingLarge.copyWith(fontSize: 25),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick an account type — you can always add the other role later.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 28),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _RoleTile(
                      title: 'Customer',
                      description: 'Browse and order fresh produce from local farmers.',
                      icon: Icons.shopping_basket_outlined,
                      accentColor: AppColors.mainGreen,
                      accentTint: AppColors.softGreen,
                      isSelected: _selectedRole == UserRole.customer,
                      onTap: () => setState(() => _selectedRole = UserRole.customer),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _RoleTile(
                      title: 'Farmer',
                      description: 'List your harvest and manage orders and stock.',
                      icon: Icons.agriculture_rounded,
                      accentColor: AppColors.autumnRust,
                      accentTint: AppColors.autumnRust.withOpacity(0.10),
                      isSelected: _selectedRole == UserRole.farmer,
                      onTap: () => setState(() => _selectedRole = UserRole.farmer),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _continue,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue as ${_selectedRole == UserRole.customer ? "Customer" : "Farmer"}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(AppPageRoute(page: const LoginScreen()));
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: AppTextStyles.bodyMuted,
                      children: const [
                        TextSpan(
                          text: 'Log In',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.accentTint,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color accentTint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? accentTint : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: accentColor, size: 20)
                else
                  Icon(Icons.radio_button_unchecked, color: AppColors.border, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12.5, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}