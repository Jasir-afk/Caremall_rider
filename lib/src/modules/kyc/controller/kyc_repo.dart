import 'dart:convert';
import 'dart:io';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/app/utils/network/logger_service.dart';
import 'package:http/http.dart' as http;
import 'package:care_mall_rider/app/utils/network/apiurls.dart';
import 'package:care_mall_rider/app/utils/network/upload_repo.dart';

/// Repository for KYC-related API calls
class KycRepo {
  /// Submits the full KYC data as a multipart form-data request.
  ///
  /// Based on the API response structure:
  /// {
  ///   "kyc": { "drivingLicence": "...", "status": "under_review" },
  ///   "vehicleDetails": { "vehicleType": "...", "registrationNumber": "..." },
  ///   "bankDetails": { ... }
  /// }
  static Future<Map<String, dynamic>> submitKyc({
    required String vehicleType,
    required String registrationNumber,
    required String licenseNumber,
    String dob = '',
    String expiryDate = '',
    File? drivingLicenceFront,
    File? drivingLicenceBack,
    String paymentMode = 'bank',
    String accountHolderName = '',
    String accountNumber = '',
    String ifscCode = '',
    String bankName = '',
    String upiId = '',
    String upiNumber = '',
  }) async {
    try {
      final String? token = await StorageService.getAuthToken();

      if (token == null || token.isEmpty) {
        Log.warning('[KycRepo] No token found — request will be Unauthorized');
      } else {
        final masked = token.length > 10
            ? '${token.substring(0, 5)}...${token.substring(token.length - 5)}'
            : '***';
        Log.debug('[KycRepo] Token found: $masked (length: ${token.length})');
      }

      // ── Step 1: Upload images first, get back CDN URLs ──────────────────
      String? drivingLicenceUrl;
      String? drivingLicenceBackUrl;

      if (drivingLicenceFront != null) {
        Log.debug('[KycRepo] Uploading driving licence front image...');
        final result = await UploadRepo.uploadImage(
          drivingLicenceFront,
          authToken: token,
        );
        if (result['success'] == true) {
          drivingLicenceUrl = result['url'] as String;
          Log.debug('[KycRepo] Front uploaded: $drivingLicenceUrl');
        } else {
          final reason = result['error'] ?? 'Unknown error';
          Log.error('[KycRepo] Front image upload failed: $reason');
          return {
            'success': false,
            'message':
                'Could not upload your driving licence front image.\n\nDetail: $reason',
          };
        }
      }

      if (drivingLicenceBack != null) {
        Log.debug('[KycRepo] Uploading driving licence back image...');
        final result = await UploadRepo.uploadImage(
          drivingLicenceBack,
          authToken: token,
        );
        if (result['success'] == true) {
          drivingLicenceBackUrl = result['url'] as String;
          Log.debug('[KycRepo] Back uploaded: $drivingLicenceBackUrl');
        } else {
          final reason = result['error'] ?? 'Unknown error';
          Log.error('[KycRepo] Back image upload failed: $reason');
          return {
            'success': false,
            'message':
                'Could not upload your driving licence back image.\n\nDetail: $reason',
          };
        }
      }

      // ── Step 2: Build JSON body ──────────────────────────────────────────
      final Map<String, dynamic> body = {
        'vehicleType': vehicleType,
        'registrationNumber': registrationNumber,
        'licenseNumber': licenseNumber,
        if (dob.isNotEmpty) 'dob': dob,
        if (expiryDate.isNotEmpty) 'expiryDate': expiryDate,
        if (drivingLicenceUrl != null) 'drivingLicenceFront': drivingLicenceUrl,
        if (drivingLicenceBackUrl != null)
          'drivingLicenceBack': drivingLicenceBackUrl,
        'paymentMode': paymentMode,
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankName': bankName,
        'upiId': upiId,
        'upiNumber': upiNumber,
      };

      Log.debug('[KycRepo] Submitting KYC JSON: $body');

      // ── Step 3: POST JSON to KYC endpoint ───────────────────────────────
      final response = await http
          .post(
            Uri.parse(ApiUrls.kycSubmit),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      Log.debug(
        '[KycRepo] KYC response ${response.statusCode}: ${response.body}',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await StorageService.saveKycStatus('under_review');
        return {
          'success': true,
          'message': responseData['message'] ?? 'KYC submitted successfully!',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              '${responseData['message'] ?? 'KYC submission failed.'} '
              '(Code: ${response.statusCode})',
          'data': responseData,
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection. ($e)',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Fetches the rider's current KYC status.
  static Future<Map<String, dynamic>> getKycStatus() async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.get(
        Uri.parse(ApiUrls.kycStatus),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true || response.statusCode == 200) {
        // Robust extraction: check root, 'data', or 'kyc' fields
        String status =
            (responseData['status'] ??
                    responseData['data']?['status'] ??
                    responseData['data']?['kyc']?['status'] ??
                    responseData['kyc']?['status'] ??
                    'pending')
                .toString();

        // Prevent overwriting a local 'under_review' with 'pending'
        // to ensure the KYC form is not shown once submitted
        final String localStatus = await StorageService.getKycStatus();
        if (localStatus == 'under_review' && status == 'pending') {
          status = 'under_review';
        }

        // Sync with local storage
        await StorageService.saveKycStatus(status);

        return {'success': true, 'status': status, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch status.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
