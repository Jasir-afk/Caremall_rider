import 'package:care_mall_rider/src/modules/home_screen/controller/home_controller.dart';
import 'package:get/get.dart';

/// HomeBinding injects HomeController for home-related screens
class HomeBinding extends Bindings {
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
