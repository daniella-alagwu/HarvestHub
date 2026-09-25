import 'package:flutter/material.dart';
import '../../presentation/theme/colors/app_colors.dart';
import '../../presentation/theme/text_styles.dart';

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.icon,
    this.hint,
    this.validator,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final IconData? icon;
  final String? hint;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary),
            style: AppTextStyles.bodyRegular
                .copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: AppTextStyles.bodyMuted,
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, color: AppColors.mainGreen, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.mainGreen, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
            items: items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item),
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }
}
