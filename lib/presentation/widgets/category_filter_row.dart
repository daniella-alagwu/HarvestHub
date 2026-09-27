import 'package:flutter/material.dart';
import '../theme/colors/app_colors.dart';
import '../theme/text_styles.dart';

class _CategoryDef {
  const _CategoryDef(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _categoryDefs = [
  _CategoryDef('Vegetables', Icons.eco),
  _CategoryDef('Fruit', Icons.local_florist),
  _CategoryDef('Bakery', Icons.bakery_dining),
  _CategoryDef('Dairy', Icons.local_drink),
];

/// Row of icon-over-label category filters — matches the Home screen's
/// Vegetables/Fruit/Bakery/Dairy row.
class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _categoryDefs.map((def) {
        final isSelected = selectedCategory == def.label;
        return GestureDetector(
          onTap: () => onSelected(def.label),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.mainGreen : AppColors.softGreen,
                ),
                child: Icon(
                  def.icon,
                  size: 22,
                  color: isSelected ? Colors.white : AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                def.label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.deepGreen : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}