import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:care_mall_rider/app/utils/network/apiurls.dart';
import 'package:care_mall_rider/app/utils/network/logger_service.dart';

class UploadRepo {
  /// Uploads an image to the general upload API.
  ///
  /// Returns a map:
  ///   { 'success': true,  'url': 'https://...' }
  ///   { 'success': false, 'error': 'reason' }
  static Future<Map<String, dynamic>> uploadImage(
    File imageFile, {
    String? authToken,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiUrls.uploadImage),
      );

      // Add headers
      if (authToken != null && authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.headers['Accept'] = 'application/json';

      final extension = imageFile.path.split('.').last.toLowerCase();
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
        ),
      );

      Log.debug('[UploadRepo] Sending request to ${ApiUrls.uploadImage}...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      Log.debug('[UploadRepo] Response status: ${response.statusCode}');
      Log.debug('[UploadRepo] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Handle multiple possible response formats
        var url =
            responseData['url'] ??
            responseData['data']?['url'] ??
            responseData['image_url'] ??
            responseData['imageUrl'] ??
            responseData['path'];

        // If 'images' is an array, take the first element
        if (url == null && responseData['images'] != null) {
          if (responseData['images'] is List &&
              (responseData['images'] as List).isNotEmpty) {
            url = responseData['images'][0];
          } else {
            url = responseData['images'];
          }
        }

        if (url != null) {
          Log.info('[UploadRepo] Image uploaded successfully: $url');
          return {'success': true, 'url': url.toString()};
        }

        final msg =
            'Upload succeeded but no URL found in response: ${response.body}';
        Log.warning('[UploadRepo] $msg');
        return {'success': false, 'error': msg};
      } else {
        final msg =
            'Upload failed — HTTP ${response.statusCode}: ${response.body}';
        Log.error('[UploadRepo] $msg');
        return {'success': false, 'error': msg};
      }
    } catch (e) {
      Log.error('[UploadRepo] Exception during image upload: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
