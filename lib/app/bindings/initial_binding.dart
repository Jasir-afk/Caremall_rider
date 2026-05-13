import 'package:care_mall_rider/app/utils/network/api_client.dart';
import 'package:care_mall_rider/core/services/connectivity_service.dart';
import 'package:get/get.dart';

/// Application-wide bindings for shared controllers and services
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Inject permanent global services
    Get.put(ConnectivityService(), permanent: true);
    Get.put(ApiClient(), permanent: true);

    // Add more global controllers here as needed
    // Get.put(AppController(), permanent: true);
  }
}
