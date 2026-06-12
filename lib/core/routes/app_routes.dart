import 'package:get/get.dart';
import 'package:care_mall_rider/app/bindings/auth_binding.dart';
import 'package:care_mall_rider/app/bindings/home_binding.dart';
import 'package:care_mall_rider/app/bindings/profile_binding.dart';
import 'package:care_mall_rider/app/bindings/kyc_binding.dart';
import 'package:care_mall_rider/src/modules/intilise_screen/view/splash_screen.dart';
import 'package:care_mall_rider/src/modules/auth/view/login_screen.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/home_screen.dart';
import 'package:care_mall_rider/src/modules/profile/view/profile_screen.dart';
import 'package:care_mall_rider/src/modules/kyc/view/kyc_verification_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String initial = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String kyc = '/kyc';
  static const String wallet = '/wallet';
}

class AppPages {
  AppPages._();
  static const initial = AppRoutes.splash;
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.kyc,
      page: () => const KycVerificationScreen(),
      binding: KYCBinding(),
    ),
    /*
    GetPage(
      name: AppRoutes.wallet,
      page: () => const WalletScreen(),
      binding: WalletBinding(),
    ),
    */
  ];
}
