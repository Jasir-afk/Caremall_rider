import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/gen/assets.gen.dart';
import 'package:care_mall_rider/src/modules/auth/view/login_screen.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/home_screen.dart';
import 'package:care_mall_rider/src/modules/kyc/controller/kyc_repo.dart';
import 'package:care_mall_rider/src/modules/kyc/view/kyc_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!mounted) return;
    if (!isLoggedIn) {
      // Not logged in → go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // Proactively fetch latest KYC status from API if logged in
      await KycRepo.getKycStatus();
      final kycDone = await StorageService.isKycCompleted();
      if (!mounted) return;
      if (kycDone) {
        // Logged in + KYC done (verified or under_review) → go to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Logged in but KYC pending or rejected → go to KYC
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
        );
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
              // App Logo
              SizedBox(
                width: 200.w,
                height: 200.h,
                child: Assets.icons.appLogoPng.image(fit: BoxFit.contain),
              ),
              SizedBox(height: 24.h),
              // App Title
              AppText(
                text: 'Care Mall Rider',
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textnaturalcolor,
              ),
              SizedBox(height: 8.h),
              // Tagline
              AppText(
                text: 'Partner with us to earn',
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textDefaultSecondarycolor,
              ),
              SizedBox(height: 48.h),
              // Loading Indicator
              SizedBox(
                width: 40.w,
                height: 40.h,
                child: CircularProgressIndicator(
                  color: AppColors.primarycolor,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
