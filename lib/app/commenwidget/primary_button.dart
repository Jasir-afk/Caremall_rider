import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standard button for primary actions in the application
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isOutline;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.isOutline = false,
  });

  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52.h,
      child: MaterialButton(
        onPressed: isLoading ? null : onPressed,
        color: isOutline
            ? Colors.transparent
            : (color ?? AppColors.primarycolor),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: isOutline
              ? BorderSide(color: color ?? AppColors.primarycolor, width: 1.5)
              : BorderSide.none,
        ),
        disabledColor: (color ?? AppColors.primarycolor).withValues(alpha: 0.5),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: isOutline
                      ? (textColor ?? AppColors.primarycolor)
                      : (textColor ?? Colors.white),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
