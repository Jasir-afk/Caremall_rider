import 'package:care_mall_rider/core/routes/app_routes.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/core/services/update_service.dart';
import 'package:care_mall_rider/gen/assets.gen.dart';
import 'package:care_mall_rider/src/modules/kyc/controller/kyc_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  void initState() {
    super.initState();
    _animateOpacity();
    _navigate();
  }

  void _animateOpacity() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));

    // Check for updates before checking user auth state
    bool updateRequired = false;
    if (mounted) {
      updateRequired = await UpdateService.checkForUpdates(context);
    }

    // If update is required, don't navigate - the dialog will block the app
    if (updateRequired) {
      return;
    }

    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      // Not logged in → go to Login
      Get.offAllNamed(AppRoutes.login);
    } else {
      // Proactively fetch latest KYC status from API if logged in
      await KycRepo.getKycStatus();
      final kycDone = await StorageService.isKycCompleted();
      if (kycDone) {
        // Logged in + KYC done (verified or under_review) → go to Home
        Get.offAllNamed(AppRoutes.home);
      } else {
        // Logged in but KYC pending or rejected → go to KYC
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
              // App Logo
              AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: 400.w,
                  height: 400.h,
                  child: Assets.icons.splashScreenLogo.image(
                    fit: BoxFit.contain,
                  ),
                ),
              ),
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
