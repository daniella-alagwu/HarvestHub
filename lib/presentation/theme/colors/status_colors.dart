import 'package:flutter/material.dart';
import 'app_colors.dart';


enum OrderStatus { pending, confirmed, readyForPickup, completed, cancelled }

class StatusColors {
  StatusColors._();

  /// order success 
  static const Color success = AppColors.success;

  /// order failed
  static const Color failure = AppColors.error;

  /// payment / order pending
  static const Color pending = AppColors.warning;

  
  static Color colorFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return pending;
      case OrderStatus.confirmed:
        return AppColors.mainGreen;
      case OrderStatus.readyForPickup:
        return AppColors.wheatGold;
      case OrderStatus.completed:
        return success;
      case OrderStatus.cancelled:
        return failure;
    }
  }

  
  static String labelFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
