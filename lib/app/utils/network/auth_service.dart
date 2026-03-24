import 'dart:convert';
import 'package:care_mall_rider/app/utils/network/logger_service.dart';
import 'package:http/http.dart' as http;
import 'package:care_mall_rider/app/utils/network/apiurls.dart';
class AuthService {
  
  /// Sends OTP to the provided phone number
  ///
  /// Parameters:
  /// - [phone]: 10-digit phone number
  /// - [mode]: "login" or "signup"
  /// - [name]: User's full name (optional for login, required for signup)
  /// - [email]: User's email (optional for login, required for signup)
  ///
  /// Returns a Map with 'success' boolean and 'message' string
  static Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String mode,
    String name = '',
    String email = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.sendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'mode': mode,
          'name': name,
          'email': email,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP sent successfully!',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to send OTP. Please try again.',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  /// Verifies the OTP entered by the user
  ///
  /// Parameters:
  /// - [phone]: 10-digit phone number
  /// - [otp]: OTP code received
  ///
  /// Returns a Map with 'success' boolean and 'message' string
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );
      final responseData = jsonDecode(response.body);
      Log.debug('[AuthService] verifyOtp raw response: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try every common token field name
        final dynamic rawData = responseData['data'] ?? responseData;
        final String? token =
            (responseData['token'] ??
                    responseData['accessToken'] ??
                    responseData['access_token'] ??
                    responseData['jwt'] ??
                    responseData['authToken'] ??
                    rawData['token'] ??
                    rawData['accessToken'] ??
                    rawData['access_token'] ??
                    rawData['jwt'] ??
                    rawData['authToken'])
                ?.toString();
        Log.info(
          '[AuthService] Extracted token: ${token != null ? "YES (len=${token.length})" : "NULL — check field name!"}',
        );
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP verified successfully!',
          'data': responseData,
          'token': token,
        };
      } else {
        return {
          'success': false,
          'message':responseData['message'] ?? 'Invalid OTP. Please try again.',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
