import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';

class FarmerNotificationsScreen extends StatelessWidget {
  const FarmerNotificationsScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  Widget build(BuildContext context) {
    final repo = FarmerDashboardRepository();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.mainGreen,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: StreamBuilder<List<NotificationModel>>(
          stream: repo.streamNotifications(farmerId),
          builder: (context, snap) {
            final notifications = snap.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.mainGreen.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text("You're all caught up.", style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _buildNotificationTile(context, repo, notifications[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, FarmerDashboardRepository repo, NotificationModel n) {
    final icon = n.type == 'low_stock' ? Icons.warning_amber_rounded : Icons.receipt_long_outlined;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.isRead ? AppColors.surface : AppColors.softGreen.withValues(alpha: 0.5),
        border: Border.all(color: n.isRead ? AppColors.border : AppColors.mainGreen.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.softGreen, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.deepGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                    ),
                    if (!n.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.mainGreen, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => repo.setNotificationRead(n.id, !n.isRead),
            child: Text(
              n.isRead ? 'Mark unread' : 'Mark read',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mainGreen),
            ),
          ),
        ],
      ),
    );
  }
}