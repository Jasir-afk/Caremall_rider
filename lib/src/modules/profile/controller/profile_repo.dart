import 'dart:convert';
import 'dart:io';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/app/utils/network/logger_service.dart';
import 'package:http/http.dart' as http;
import 'package:care_mall_rider/app/utils/network/apiurls.dart';
import 'package:care_mall_rider/app/utils/network/upload_repo.dart';

class ProfileRepo {
  /// Fetch rider profile
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await StorageService.getAuthToken();
    final response = await http.get(
      Uri.parse(ApiUrls.getProfile),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load profile (${response.statusCode})');
    }
  }

  /// Update profile — supports avatar upload + all editable fields
  static Future<Map<String, dynamic>> updateProfile({
    // Basic
    String? name,
    String? email,
    String? address,
    File? avatar,
    // Payment
    String? paymentMode,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
    String? upiId,
    String? upiNumber,
    // Vehicle
    String? vehicleType,
    String? registrationNumber,
    bool removeAvatar = false,
  }) async {
    final token = await StorageService.getAuthToken();
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse(ApiUrls.updateProfile),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    // Basic fields
    if (name != null) request.fields['name'] = name;
    if (email != null) request.fields['email'] = email;
    if (address != null) request.fields['address'] = address;
    // Avatar
    if (avatar != null) {
      Log.debug('[ProfileRepo] Uploading avatar image...');
      final result = await UploadRepo.uploadImage(avatar, authToken: token);
      if (result['success'] == true) {
        final url = result['url'] as String;
        Log.debug('[ProfileRepo] Avatar uploaded successfully: $url');
        request.fields['avatar'] = url;
      } else {
        final reason = result['error'] ?? 'Unknown error';
        Log.error('[ProfileRepo] Avatar upload failed: $reason');
        return {
          'success': false,
          'message':
              'Could not upload your avatar. '
              'Please check your connection and try again.',
        };
      }
    }
    // Payment fields
    if (paymentMode != null) request.fields['paymentMode'] = paymentMode;
    if (accountHolderName != null) {
      request.fields['accountHolderName'] = accountHolderName;
    }
    if (accountNumber != null) request.fields['accountNumber'] = accountNumber;
    if (ifscCode != null) request.fields['ifscCode'] = ifscCode;
    if (bankName != null) request.fields['bankName'] = bankName;
    if (upiId != null) request.fields['upiId'] = upiId;
    if (upiNumber != null) request.fields['upiNumber'] = upiNumber;
    // Vehicle fields
    if (vehicleType != null) request.fields['vehicleType'] = vehicleType;
    if (registrationNumber != null) {
      request.fields['registrationNumber'] = registrationNumber;
    }
    if (removeAvatar) {
      request.fields['removeAvatar'] = 'true';
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to update profile.',
      };
    }
  }
}
