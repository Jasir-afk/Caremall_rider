import 'dart:convert';
import 'dart:io';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:care_mall_rider/app/utils/network/apiurls.dart';

import 'package:care_mall_rider/src/modules/home_screen/model/dashboard_model.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/delivery_order_model.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/return_order_model.dart';

class OrderRepo {
  /// Fetch all delivery orders assigned to this rider.
  static Future<List<DeliveryOrder>> getDeliveryOrders() async {
    final token = await StorageService.getAuthToken();

    final response = await http.get(
      Uri.parse(ApiUrls.deliveryOrders),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['orders'] as List<dynamic>? ?? [];
      return list
          .map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load orders (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Fetch dashboard statistics for the rider.
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await StorageService.getAuthToken();

    final response = await http.get(
      Uri.parse(ApiUrls.dashboard),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      // Handle "data" wrapper if it exists, otherwise return body
      return body['data'] ?? body;
    } else {
      throw Exception(
        'Failed to load dashboard stats (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Fetch full dashboard with summary stats and today's orders.
  static Future<DashboardModel> getDashboard() async {
    final token = await StorageService.getAuthToken();

    final response = await http
        .get(
          Uri.parse(ApiUrls.dashboard),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return DashboardModel.fromJson(body);
    } else {
      throw Exception(
        'Failed to load dashboard (${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<DashboardModel> getDeliveredTodayData() async {
    final token = await StorageService.getAuthToken();
    try {
      final response = await http
          .get(
            Uri.parse(ApiUrls.deliveryOrders),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        Map<String, dynamic> data;
        if (body is List) {
          data = {'success': true, 'todayOrders': body};
        } else {
          data = Map<String, dynamic>.from(body);
        }
        return DashboardModel.fromJson(data);
      } else {
        throw Exception(
          'Failed to load today\'s orders (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load delivered today data: $e');
    }
  }

  /// Fetch a single order by its MongoDB document ID.
  static Future<DeliveryOrder> getOrderDetail(String orderId) async {
    final token = await StorageService.getAuthToken();

    final response = await http.get(
      Uri.parse(ApiUrls.orderDetail(orderId)),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return DeliveryOrder.fromJson(body['order'] as Map<String, dynamic>);
    } else {
      throw Exception(
        'Failed to load order detail (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Upload a delivery proof photo for an order (PATCH multipart).
  static Future<Map<String, dynamic>> uploadDeliveryPhoto({
    required String orderId,
    required File photo,
  }) async {
    final token = await StorageService.getAuthToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiUrls.orderUploadPhoto(orderId)),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    final ext = photo.path.split('.').last.toLowerCase();
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to upload photo.',
      };
    }
  }

  /// Fetch all return orders assigned to this rider.
  static Future<List<ReturnOrder>> getReturnOrders() async {
    final token = await StorageService.getAuthToken();

    final response = await http.get(
      Uri.parse(ApiUrls.returnsOrders),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> list = [];

      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        // 1. Try common keys at top level
        final topLevelSource =
            decoded['returns'] ??
            decoded['returnOrders'] ??
            decoded['refunds'] ??
            decoded['refundOrders'] ??
            decoded['orders'] ??
            decoded['return'] ??
            decoded['data'];

        if (topLevelSource is List) {
          list = topLevelSource;
        } else if (topLevelSource is Map) {
          // 2. If 'data' or similar was a map, look inside it
          final secondarySource =
              topLevelSource['returns'] ??
              topLevelSource['refunds'] ??
              topLevelSource['refundOrders'] ??
              topLevelSource['orders'] ??
              topLevelSource['returnOrders'] ??
              topLevelSource['data'];
          if (secondarySource is List) {
            list = secondarySource;
          }
        }
      }

      return list
          .map((e) => ReturnOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load returns (${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final token = await StorageService.getAuthToken();

    final response = await http.patch(
      Uri.parse(ApiUrls.orderUpdateStatus(orderId)),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to update order status.',
      };
    }
  }

  /// Report delivery failure (Cannot Deliver)
  static Future<Map<String, dynamic>> reportFailedOrder({
    required String orderId,
    required String reason,
  }) async {
    final token = await StorageService.getAuthToken();

    final response = await http.post(
      Uri.parse(ApiUrls.orderFailed(orderId)),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reason': reason}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to report delivery issue.',
      };
    }
  }

  /// Send delivery OTP to customer
  static Future<Map<String, dynamic>> sendDeliveryOTP({
    required String orderId,
  }) async {
    final token = await StorageService.getAuthToken();

    try {
      final response = await http.post(
        Uri.parse(ApiUrls.orderSendOTP(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message':
              body['message'] ??
              'Send OTP failed (${response.statusCode}). The backend may not support this endpoint yet.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Verify delivery OTP and complete order
  static Future<Map<String, dynamic>> completeOrderWithOTP({
    required String orderId,
    required String otp,
  }) async {
    final token = await StorageService.getAuthToken();

    try {
      final response = await http.post(
        Uri.parse(ApiUrls.orderVerifyOTP(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otp': otp}),
      );

      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to verify OTP.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Fetch a single return order by its ID.
  static Future<ReturnOrder> getReturnDetail(String returnId) async {
    final token = await StorageService.getAuthToken();

    final response = await http.get(
      Uri.parse(ApiUrls.returnDetail(returnId)),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      // Try common root keys
      final data =
          body['return'] ??
          body['returnOrder'] ??
          body['order'] ??
          body['data'] ??
          body;
      return ReturnOrder.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(
        'Failed to load return detail (${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> updateReturnStatus({
    required String returnId,
    required String status,
    String? pickupStatus,
  }) async {
    final token = await StorageService.getAuthToken();

    final response = await http.patch(
      Uri.parse(ApiUrls.returnUpdateStatus(returnId)),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status, 'pickupStatus': pickupStatus}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to update return status.',
      };
    }
  }

  static Future<Map<String, dynamic>> updateReturnItemStatus({
    required String returnId,
    required String returnItemStatus,
    String? orderStatus,
    String? pickStatus,
    String? pickupStatus,
    String? refundStatus,
    String? replacementDeliveryStatus,
    bool? isPicked,
    bool? isDropped,
  }) async {
    final token = await StorageService.getAuthToken();

    final response = await http.patch(
      Uri.parse(ApiUrls.returnUpdateItemStatus(returnId)),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'returnItemStatus': returnItemStatus,
        if (orderStatus != null) 'status': orderStatus,
        if (pickStatus != null) 'pickStatus': pickStatus,
        if (pickupStatus != null) 'pickupStatus': pickupStatus,
        if (refundStatus != null) 'refundStatus': refundStatus,
        if (replacementDeliveryStatus != null)
          'replacementDeliveryStatus': replacementDeliveryStatus,
        if (isPicked != null) 'isPicked': isPicked,
        if (isDropped != null) 'isDropped': isDropped,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to update return item status.',
      };
    }
  }

  static Future<Map<String, dynamic>> uploadReturnPhoto({
    required String returnId,
    required File photo,
  }) async {
    final token = await StorageService.getAuthToken();
    final url = ApiUrls.returnUploadPhoto(returnId);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Field name expected by backend
          photo.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Upload failed.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update the replacement delivery status for a return order.
  static Future<Map<String, dynamic>> updateReturnReplacementStatus({
    required String returnId,
    required String replacementDeliveryStatus,
  }) async {
    final token = await StorageService.getAuthToken();

    final response = await http.patch(
      Uri.parse(ApiUrls.returnUpdateReplacementStatus(returnId)),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'replacementDeliveryStatus': replacementDeliveryStatus,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to update replacement status.',
      };
    }
  }
}
