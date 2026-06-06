import 'package:care_mall_rider/core/routes/app_routes.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/gen/assets.gen.dart';
import 'package:care_mall_rider/src/modules/kyc/controller/kyc_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      await KycRepo.getKycStatus();
      final kycDone = await StorageService.isKycCompleted();
      if (kycDone) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.kyc);
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200.w,
                height: 200.h,
                child: Assets.icons.appLogoPng.image(fit: BoxFit.contain),
              ),
              // SizedBox(height: 24.h),
              // AppText(
              //   text: 'Care Mall Rider',
              //   fontSize: 28.sp,
              //   fontWeight: FontWeight.w700,
              //   color: AppColors.textnaturalcolor,
              // ),
              // SizedBox(height: 8.h),
              // AppText(
              //   text: 'Partner with us to earn',
              //   fontSize: 16.sp,
              //   fontWeight: FontWeight.w400,
              //   color: AppColors.textDefaultSecondarycolor,
              // ),
              // SizedBox(height: 48.h),
              // SizedBox(
              //   width: 40.w,
              //   height: 40.h,
              //   child: CircularProgressIndicator(
              //     color: AppColors.primarycolor,
              //     strokeWidth: 3,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
