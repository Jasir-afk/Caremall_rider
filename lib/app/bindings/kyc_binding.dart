import 'package:care_mall_rider/src/modules/kyc/controller/kyc_controller.dart';
import 'package:get/get.dart';

/// KYCBinding injects KYCController for KYC verification screens
class KYCBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KYCController>(() => KYCController());
  }
}
