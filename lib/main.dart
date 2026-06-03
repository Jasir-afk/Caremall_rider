import 'package:care_mall_rider/app/bindings/initial_binding.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/core/routes/app_routes.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/src/modules/intilise_screen/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize persistent storage
  await StorageService.init();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard mobile design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          color: AppColors.whitecolor,
          title: 'Care Mall Rider',
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: AppColors.primarycolor,
            scaffoldBackgroundColor: AppColors.whitecolor,
            canvasColor: AppColors.whitecolor,
            cardColor: AppColors.whitecolor,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.whitecolor,
              surfaceTintColor: AppColors.whitecolor,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: AppColors.whitecolor,
              surfaceTintColor: AppColors.whitecolor,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.whitecolor,
              surfaceTintColor: AppColors.whitecolor,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primarycolor,
              surface: AppColors.whitecolor,
            ),
          ),
          initialBinding:
              InitialBinding(), // Automatically initializes global controllers
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
          home: const SplashScreen(),
        );
      },
    );
  }
}
