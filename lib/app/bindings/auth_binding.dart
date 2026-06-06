import 'package:care_mall_rider/src/modules/auth/controller/auth_controller.dart';
import 'package:get/get.dart';

/// AuthBinding injects AuthController for authentication-related screens
class AuthBinding extends Bindings {
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
