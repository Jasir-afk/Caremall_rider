import 'package:care_mall_rider/src/modules/profile/controller/profile_controller.dart';
import 'package:get/get.dart';

/// ProfileBinding injects ProfileController for profile-related screens
class ProfileBinding extends Bindings {
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
