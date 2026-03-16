import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/core/services/connectivity_service.dart';
import 'package:care_mall_rider/src/modules/intilise_screen/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize persistent storage
  await StorageService.init();
  // Initialize connectivity monitoring
  Get.put(ConnectivityService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard mobile design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          color: Colors.white,
          title: 'Care Mall Rider',
          theme: ThemeData(useMaterial3: true),
          home: const SplashScreen(),
        );
      },
    );
  }
}
