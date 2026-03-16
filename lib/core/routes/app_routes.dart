import 'package:get/get.dart';
import 'package:care_mall_rider/src/modules/intilise_screen/view/splash_screen.dart';
// Import other views as they are implemented

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
    // Add other pages here
    /*
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpVerificationScreen(),
    ),
    */
  ];
}
