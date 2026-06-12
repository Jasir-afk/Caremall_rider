import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:care_mall_rider/app/utils/network/apiurls.dart';

/// Repository class for authentication-related API calls
/// Follows the repository pattern to separate data layer from business logic
class AuthRepo {
  /// Sends OTP to the provided phone number
  ///
  /// Parameters:
  /// - [phone]: 10-digit phone number
  /// - [mode]: "login" or "signup"
  /// - [name]: User's full name (optional for login, required for signup)
  /// - [email]: User's email (optional for login, required for signup)
  ///
  /// Returns a Map with API response data
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
        // Check for account_deleted status
        final status = responseData['status'];
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to send OTP. Please try again.',
          'data': responseData,
          'status': status, // Include status field for account_deleted handling
        };
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message':
              'Failed to connect to server. Please check your internet connection or server status.',
        };
      }
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Verifies the OTP entered by the user
  ///
  /// Parameters:
  /// - [phone]: 10-digit phone number
  /// - [otp]: OTP code received
  ///
  /// Returns a Map with API response data
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

        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP verified successfully!',
          'data': responseData,
          'token': token,
          'user': responseData['deliveryBoy'], // Save user data if provided
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Invalid OTP. Please try again.',
          'data': responseData,
        };
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message':
              'Failed to connect to server. Please check your internet connection or server status.',
        };
      }
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Gets the rider's current online status
  ///
  /// Parameters:
  /// - [token]: Authentication token
  ///
  /// Returns a Map with API response data
  static Future<Map<String, dynamic>> getOnlineStatus({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiUrls.onlineStatus),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to get status. Please try again.',
          'data': responseData,
        };
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message':
              'Failed to connect to server. Please check your internet connection or server status.',
        };
      }
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Toggles the rider's online status
  ///
  /// Parameters:
  /// - [isOnline]: Boolean indicating online status (true for online, false for offline)
  /// - [token]: Authentication token
  ///
  /// Returns a Map with API response data
  static Future<Map<String, dynamic>> toggleOnlineStatus({
    required bool isOnline,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiUrls.toggleOnlineStatus),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isOnline': isOnline}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Status updated successfully!',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to update status. Please try again.',
          'data': responseData,
        };
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message':
              'Failed to connect to server. Please check your internet connection or server status.',
        };
      }
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
