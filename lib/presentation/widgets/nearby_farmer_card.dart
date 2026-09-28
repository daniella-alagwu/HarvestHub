import 'package:flutter/material.dart';
import '../../data/models/farmer_model.dart';
import '../theme/colors/app_colors.dart';
import '../theme/text_styles.dart';


class NearbyFarmerCard extends StatelessWidget {
  const NearbyFarmerCard({super.key, required this.farmer, this.onTap});

  final Farmer farmer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.deepGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.mainGreen,
              backgroundImage: farmer.avatarUrl != null
                  ? NetworkImage(farmer.avatarUrl!)
                  : null,
              child: farmer.avatarUrl == null
                  ? const Icon(Icons.agriculture, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmer.businessName,
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                                    Text(
                    '${farmer.distanceLabel} • ${farmer.marketDay}',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${farmer.tagline} • ${farmer.productsCount} products',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}