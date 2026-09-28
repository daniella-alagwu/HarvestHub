import 'package:flutter/material.dart';

import '../theme/colors/app_colors.dart';
import '../theme/text_styles.dart';

class _CategoryDef {
  const _CategoryDef({
    required this.label,
    required this.imagePath,
  });

  final String label;
  final String imagePath;
}

const _categories = [
  _CategoryDef(
    label: 'Vegetables',
    imagePath: 'assets/images/categories/vegetables.jpg',
  ),
  _CategoryDef(
    label: 'Fruits',
    imagePath: 'assets/images/categories/fruits.jpg',
  ),
  _CategoryDef(
    label: 'Bakery',
    imagePath: 'assets/images/categories/bakery.jpg',
  ),
  _CategoryDef(
    label: 'Dairy',
    imagePath: 'assets/images/categories/dairy.jpg',
  ),
  _CategoryDef(
    label: 'Tubers & Roots',
    imagePath: 'assets/images/categories/tubers.jpeg',
  ),
  _CategoryDef(
    label: 'Grains & Cereals',
    imagePath: 'assets/images/categories/grains.jpeg',
  ),
  _CategoryDef(
    label: 'Oil & Oilseeds',
    imagePath: 'assets/images/categories/oil.jpeg',
  ),
  _CategoryDef(
    label: 'Spices',
    imagePath: 'assets/images/categories/spices.jpeg',
  ),
  _CategoryDef(
    label: 'Legumes & Pulses',
    imagePath: 'assets/images/categories/legumes.jpeg',
  ),
];

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
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
        ),
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];

          final isSelected =
              selectedCategory == category.label;

          return GestureDetector(
            onTap: () => onSelected(category.label),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 78,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.mainGreen
                          : AppColors.softGreen,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.mainGreen
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.mainGreen
                                    .withOpacity(0.18),
                                blurRadius: 8,
                                offset:
                                    const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            category.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                              return Container(
                                color: AppColors.softGreen,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color:
                                      AppColors.mainGreen,
                                  size: 24,
                                ),
                              );
                            },
                          ),

                          if (isSelected)
                            Container(
                              color: Colors.black
                                  .withOpacity(0.15),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    category.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style:
                        AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.deepGreen
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 10.5,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}