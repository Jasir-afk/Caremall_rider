import 'package:care_mall_rider/app/utils/network/apiurls.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/app/utils/network/logger_service.dart';
import 'package:get/get.dart';

/// Base API client using GetConnect for handling HTTP requests
class ApiClient extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ApiUrls.baseURL;
    httpClient.timeout = const Duration(seconds: 30);

    // Request Modifier: Add Auth Token to Headers
    httpClient.addRequestModifier<dynamic>((request) async {
      final token = await StorageService.getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      Log.debug('API Request: [${request.method}] ${request.url}');
      return request;
    });

    // Response Modifier: Handle Global Errors or Token Refresh
    httpClient.addResponseModifier<dynamic>((request, response) {
      if (response.hasError) {
        Log.error(
          'API Error: [${response.statusCode}] ${response.statusText}\nBody: ${response.body}',
        );
      } else {
        Log.debug('API Success: [${response.statusCode}] ${request.url}');
      }
      return response;
    });

    super.onInit();
  }

  /// Global error handling for common HTTP status codes
  Response handleResponse(Response response) {
    if (response.statusCode == 401) {
      // Handle Unauthorized: logout or refresh token
      Log.warning('Unauthorized request - redirecting to login');
      // Get.offAllNamed(AppRoutes.login);
    }
    return response;
  }
}
