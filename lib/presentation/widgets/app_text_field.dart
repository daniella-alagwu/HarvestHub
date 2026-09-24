import 'package:flutter/material.dart';
import '../theme/colors/app_colors.dart';
import '../theme/text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.icon,
    this.iconColor,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? icon;
  final Color? iconColor;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: obscureText ? 1 : maxLines,
          style: AppTextStyles.bodyRegular,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMuted,
            prefixIcon: icon != null
                ? Icon(icon, color: iconColor ?? AppColors.deepGreen, size: 20)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}