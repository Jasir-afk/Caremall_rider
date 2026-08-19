import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/app/utils/sized_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.child,
    this.isValid = true,
    this.btncolor,
    this.textcolor,
    this.buttonStyle,
    this.isLoading = false,
    this.height,
    this.width,
    this.borderRadius = 8.0,
    this.onPressed,
  });

  final Widget? child;
  final Color? btncolor, textcolor;
  final VoidCallback? onPressed;
  final ButtonStyle? buttonStyle;
  final double? height, width;
  final bool? isValid;
  final bool isLoading;
  final double borderRadius; // 👈 dynamic border radius

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? ScreenUtil().screenWidth,
      height: height ?? 50,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main button
          ElevatedButton(
            style:
                buttonStyle ??
                ButtonStyle(
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                  backgroundColor: WidgetStatePropertyAll(
                    btncolor ?? AppColors.primarycolor,
                  ),
                  shadowColor: const WidgetStatePropertyAll(
                    AppColors.primarycolor,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                ),
            onPressed: onPressed,
            child:
                child ??
                AppText(
                  text: '',
                  color: textcolor ?? AppColors.whitecolor,
                  fontSize: 17,
                  letterspace: 0.1,
                  fontWeight: FontWeight.w600,
                ),
          ),

          // Disabled overlay
          isValid == true
              ? 0.hBox
              : ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      AppColors.textDefaultSecondarycolor.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    shadowColor: const WidgetStatePropertyAll(
                      AppColors.textDefaultSecondarycolor,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                  ),
                  onPressed: () {},
                  child: const SizedBox.shrink(),
                ),

          // Loading overlay
          isLoading == false
              ? 0.hBox
              : ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      AppColors.textDefaultSecondarycolor.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    shadowColor: const WidgetStatePropertyAll(
                      AppColors.textDefaultSecondarycolor,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                  ),
                  onPressed: () {},
                  child: const CupertinoActivityIndicator(
                    color: AppColors.whitecolor,
                    radius: 8,
                  ),
                ),
        ],
      ),
    );
  }
}
