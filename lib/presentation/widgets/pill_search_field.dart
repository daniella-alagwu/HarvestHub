import 'package:flutter/material.dart';
import '../theme/colors/app_colors.dart';
import '../theme/text_styles.dart';

class PillSearchField extends StatelessWidget {
  const PillSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.trailing,
    this.onTap,
    this.readOnly = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              readOnly: readOnly,
              style: AppTextStyles.bodyRegular,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMuted,
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}