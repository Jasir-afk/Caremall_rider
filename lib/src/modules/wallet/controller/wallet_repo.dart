import 'dart:convert';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:care_mall_rider/app/utils/network/apiurls.dart';
import 'package:care_mall_rider/src/modules/wallet/model/wallet_model.dart';
import 'package:care_mall_rider/src/modules/wallet/model/withdrawal_request_model.dart';

class WalletRepo {
  static Future<WalletModel> getWalletData() async {
    final token = await StorageService.getAuthToken();

    final response = await http
        .get(
          Uri.parse(ApiUrls.wallet),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = Map<String, dynamic>.from(jsonDecode(response.body));
      final data = body['data'] ?? body['wallet'] ?? body;
      return WalletModel.fromJson(
        Map<String, dynamic>.from(data is Map ? data : body),
      );
    } else {
      throw Exception(
        'Failed to load wallet data (${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> requestWithdrawal(num amount) async {
    final token = await StorageService.getAuthToken();

    final response = await http
        .post(
          Uri.parse(ApiUrls.withdraw),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'amount': amount}),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': body['message'] ?? 'Withdrawal requested',
      };
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to request withdrawal',
      };
    }
  }

  static Future<List<WithdrawalRequest>> getWithdrawalRequests() async {
    final token = await StorageService.getAuthToken();

    final response = await http
        .get(
          Uri.parse(ApiUrls.withdrawalRequests),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final requests = body['requests'] as List<dynamic>? ?? [];
      return requests
          .map((e) => WithdrawalRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load withdrawal requests (${response.statusCode}): ${response.body}',
      );
    }
  }
}
