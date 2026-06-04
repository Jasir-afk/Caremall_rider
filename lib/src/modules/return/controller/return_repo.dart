import 'dart:io';

import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';
import 'package:care_mall_rider/src/modules/return/model/return_order_model.dart';

class ReturnRepo {
  static Future<List<ReturnOrder>> getReturnOrders() {
    return OrderRepo.getReturnOrders();
  }

  static Future<ReturnOrder> getReturnDetail(String returnId) {
    return OrderRepo.getReturnDetail(returnId);
  }

  static Future<Map<String, dynamic>> updateReturnStatus({
    required String returnId,
    required String status,
    String? pickupStatus,
  }) {
    return OrderRepo.updateReturnStatus(
      returnId: returnId,
      status: status,
      pickupStatus: pickupStatus,
    );
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
  }) {
    return OrderRepo.updateReturnItemStatus(
      returnId: returnId,
      returnItemStatus: returnItemStatus,
      orderStatus: orderStatus,
      pickStatus: pickStatus,
      pickupStatus: pickupStatus,
      refundStatus: refundStatus,
      replacementDeliveryStatus: replacementDeliveryStatus,
      isPicked: isPicked,
      isDropped: isDropped,
    );
  }

  static Future<Map<String, dynamic>> uploadReturnPhoto({
    required String returnId,
    required File photo,
  }) {
    return OrderRepo.uploadReturnPhoto(returnId: returnId, photo: photo);
  }

  static Future<Map<String, dynamic>> updateReturnReplacementStatus({
    required String returnId,
    required String replacementDeliveryStatus,
    String? orderStatus,
    String? pickupStatus,
  }) {
    return OrderRepo.updateReturnReplacementStatus(
      returnId: returnId,
      replacementDeliveryStatus: replacementDeliveryStatus,
      orderStatus: orderStatus,
      pickupStatus: pickupStatus,
    );
  }

  /// PATCH /api/v1/rider/returns/:id/replacement-pickup-status
  /// replacementPickupStatus: 'replacement_pick' | 'replacement_delivered'
  static Future<Map<String, dynamic>> updateReplacementPickupStatus({
  required String returnId,
  required String replacementPickupStatus,
}){
  return OrderRepo.updateReplacementPickupStatus(
    returnId: returnId,
    replacementPickupStatus: replacementPickupStatus,
  );
}
}
