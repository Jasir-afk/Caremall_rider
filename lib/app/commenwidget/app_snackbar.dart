import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Centralized utility for consistent snackbars across the app
class AppSnackbar {
  /// Displays a success snackbar with a green icon and border.
  static void showSuccess({required String title, required String message}) {
    _showSnackbar(
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF10B981),
      borderColor: const Color(0xFF10B981),
    );
  }

  /// Displays an error snackbar with a red icon and border.
  static void showError({required String title, required String message}) {
    _showSnackbar(
      title: title,
      message: message,
      icon: Icons.error_rounded,
      iconColor: const Color(0xFFEF4444),
      borderColor: const Color(0xFFEF4444),
    );
  }

  /// Displays an info snackbar with a blue icon and border.
  static void showInfo({required String title, required String message}) {
    _showSnackbar(
      title: title,
      message: message,
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF3B82F6),
      borderColor: const Color(0xFF3B82F6),
    );
  }

  /// Displays a minimal earnings/credits snackbar with a wallet icon.
  static void showEarnings({required double amount, String? message}) {
    Get.closeAllSnackbars();
    Get.rawSnackbar(
      titleText: Text(
        '₹${amount.toStringAsFixed(2)} Earned',
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textnaturalcolor,
        ),
      ),
      messageText: Text(
        message ?? '${amount.toStringAsFixed(0)} rupees earned',
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      icon: Padding(
        padding: EdgeInsets.only(left: 14.w),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color: const Color(0xFF10B981), // Clean success green
          size: 26.sp,
        ),
      ),
      shouldIconPulse: false,
      backgroundColor: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      borderRadius: 12.r,
      borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
      borderWidth: 1.5,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeIn,
    );
  }


  /// Internal method to show consistent styled GetX snackbars
  static void _showSnackbar({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
  }) {
    Get.closeAllSnackbars();
    Get.rawSnackbar(
      titleText: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textnaturalcolor,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
      icon: Padding(
        padding: EdgeInsets.only(left: 14.w),
        child: Icon(icon, color: iconColor, size: 28.sp),
      ),
      shouldIconPulse: false,
      backgroundColor: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      borderRadius: 12.r,
      borderColor: borderColor.withValues(alpha: 0.3),
      borderWidth: 1.5,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeIn,
    );
  }
}
