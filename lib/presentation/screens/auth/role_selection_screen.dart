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
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState
    extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.customer;

  Color get _accent =>
      _selectedRole == UserRole.customer
          ? AppColors.mainGreen
          : AppColors.autumnRust;

  void _continue() {
    Navigator.of(context).push(
      AppPageRoute(
        page: RegisterScreen(
          role: _selectedRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer =
        _selectedRole == UserRole.customer;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
           
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      splashRadius: 20,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.deepGreen,
                      ),
                      onPressed: () =>
                          Navigator.of(context)
                              .maybePop(),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'STEP 1 OF 2',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.wheatGold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 28),

                    Text(
                      'Choose your role',
                      style: AppTextStyles.headingLarge
                          .copyWith(
                        fontSize: 28,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Tell us how you’ll use HarvestHub so we can set up the right experience for you.',
                      style: AppTextStyles.bodyMuted.copyWith(
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 28),

                    
                    _RoleCard(
                      title: 'Customer',
                      description:
                          'Discover local produce, compare products, and place orders from farmers near you.',
                      icon:
                          Icons.shopping_bag_rounded,
                      accentColor:
                          AppColors.mainGreen,
                      accentTint:
                          AppColors.softGreen,
                      isSelected: isCustomer,
                      onTap: () {
                        setState(
                          () => _selectedRole =
                              UserRole.customer,
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    //farmer
                    _RoleCard(
                      title: 'Farmer',
                      description:
                          'Showcase your harvest, manage your stock, and keep track of customer orders.',
                      icon:
                          Icons.agriculture_rounded,
                      accentColor:
                          AppColors.autumnRust,
                      accentTint:
                          AppColors.autumnRust
                              .withOpacity(0.10),
                      isSelected:
                          !isCustomer,
                      onTap: () {
                        setState(
                          () => _selectedRole =
                              UserRole.farmer,
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // --------------------------------------------------
                    // HELPER TEXT
                    // --------------------------------------------------
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color:
                                AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You can always explore the other side of the marketplace later.',
                              style: AppTextStyles.caption
                                  .copyWith(
                                fontSize: 11.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ----------------------------------------------------------
            // BOTTOM ACTION AREA
            // ----------------------------------------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(
                24,
                14,
                24,
                16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _continue,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              isCustomer
                                  ? 'Continue as Customer'
                                  : 'Continue as Farmer',
                              style: AppTextStyles
                                  .buttonLabel
                                  .copyWith(
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          AppPageRoute(
                            page:
                                const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor:
                            AppColors.deepGreen,
                      ),
                      child: RichText(
                        text: TextSpan(
                          text:
                              'Already have an account? ',
                          style:
                              AppTextStyles.bodyMuted,
                          children: const [
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(
                                color:
                                    AppColors.deepGreen,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 142,
          ),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected
                ? accentTint
                : AppColors.surface,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : AppColors.border,
              width: isSelected ? 1.7 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color:
                          accentColor.withOpacity(
                        0.10,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(
                        0.025,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              // --------------------------------------------------------
              // ROLE ICON
              // --------------------------------------------------------
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : accentTint,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  size: 31,
                  color: isSelected
                      ? Colors.white
                      : accentColor,
                ),
              ),

              const SizedBox(width: 16),

              // --------------------------------------------------------
              // ROLE TEXT
              // --------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles
                          .headingMedium
                          .copyWith(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: AppTextStyles
                          .bodyMuted
                          .copyWith(
                        fontSize: 12.2,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // --------------------------------------------------------
              // SELECTOR
              // --------------------------------------------------------
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? accentColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}