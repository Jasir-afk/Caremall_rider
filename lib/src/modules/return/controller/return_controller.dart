import 'dart:io';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/src/modules/return/controller/return_repo.dart';
import 'package:care_mall_rider/src/modules/return/model/return_order_model.dart';
import 'package:get/get.dart';

/// ReturnController manages return order state and operations
class ReturnController extends GetxController {
  // Observable states
  final isLoading = false.obs;
  final isUpdating = false.obs;
  final isUploading = false.obs;
  final errorMessage = Rxn<String>();

  // Return orders data
  final returnOrders = <ReturnOrder>[].obs;
  final selectedReturnOrder = Rxn<ReturnOrder>();

  // Selected photo for upload
  final selectedPhoto = Rxn<File>();

  void onInit() {
    super.onInit();
    fetchReturnOrders();
  }

  /// Fetch all return orders
  Future<void> fetchReturnOrders() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final orders = await ReturnRepo.getReturnOrders();
      // Fetch details for all return orders to get returnItemStatus
      for (int i = 0; i < orders.length; i++) {
        try {
          final detail = await ReturnRepo.getReturnDetail(orders[i].id);
          orders[i] = detail;
        } catch (e) {
          print('Failed to fetch detail for order at index $i: $e');
        }
      }
      returnOrders.assignAll(orders);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch single return order detail
  Future<void> fetchReturnDetail(String returnId) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final detail = await ReturnRepo.getReturnDetail(returnId);
      selectedReturnOrder.value = detail;

      // Update in the list if exists
      final index = returnOrders.indexWhere((r) => r.id == returnId);
      if (index != -1) {
        returnOrders[index] = detail;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to load return details: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update return status
  Future<void> updateReturnStatus({
    required String returnId,
    required String status,
    String? pickupStatus,
  }) async {
    try {
      isUpdating.value = true;

      final result = await ReturnRepo.updateReturnStatus(
        returnId: returnId,
        status: status,
        pickupStatus: pickupStatus,
      );

      if (result['success'] == true) {
        AppSnackbar.showSuccess(
          title: 'Success',
          message: 'Return status updated',
        );
        await fetchReturnDetail(returnId);
      } else {
        AppSnackbar.showError(
          title: 'Update Failed',
          message: result['message'] ?? 'Failed to update return status',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to update return status: $e',
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Update return item status
  Future<void> updateReturnItemStatus({
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
    try {
      isUpdating.value = true;

      final result = await ReturnRepo.updateReturnItemStatus(
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

      if (result['success'] == true) {
        AppSnackbar.showSuccess(
          title: 'Success',
          message: 'Return item status updated',
        );
        await fetchReturnDetail(returnId);
      } else {
        AppSnackbar.showError(
          title: 'Update Failed',
          message: result['message'] ?? 'Failed to update return item status',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to update return item status: $e',
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Upload return photo
  Future<void> uploadReturnPhoto({
    required String returnId,
    required File photo,
  }) async {
    try {
      isUploading.value = true;

      final result = await ReturnRepo.uploadReturnPhoto(
        returnId: returnId,
        photo: photo,
      );

      if (result['success'] == true) {
        AppSnackbar.showSuccess(
          title: 'Success',
          message: 'Photo uploaded successfully',
        );
        selectedPhoto.value = null;
        await fetchReturnDetail(returnId);
      } else {
        AppSnackbar.showError(
          title: 'Upload Failed',
          message: result['message'] ?? 'Failed to upload photo',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to upload photo: $e',
      );
    } finally {
      isUploading.value = false;
    }
  }

  /// Update return replacement status
  Future<void> updateReturnReplacementStatus({
    required String returnId,
    required String replacementDeliveryStatus,
    String? orderStatus,
    String? pickupStatus,
  }) async {
    try {
      isUpdating.value = true;

      final result = await ReturnRepo.updateReturnReplacementStatus(
        returnId: returnId,
        replacementDeliveryStatus: replacementDeliveryStatus,
        orderStatus: orderStatus,
        pickupStatus: pickupStatus,
      );

      if (result['success'] == true) {
        AppSnackbar.showSuccess(
          title: 'Success',
          message: 'Replacement status updated',
        );
        await fetchReturnDetail(returnId);
      } else {
        AppSnackbar.showError(
          title: 'Update Failed',
          message: result['message'] ?? 'Failed to update replacement status',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to update replacement status: $e',
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Update replacement pickup status
  Future<void> updateReplacementPickupStatus({
    required String returnId,
    required String replacementPickupStatus,
  }) async {
    try {
      isUpdating.value = true;

      final result = await ReturnRepo.updateReplacementPickupStatus(
        returnId: returnId,
        replacementPickupStatus: replacementPickupStatus,
      );

      if (result['success'] == true) {
        AppSnackbar.showSuccess(
          title: 'Success',
          message: 'Replacement pickup status updated',
        );
        await fetchReturnDetail(returnId);
        // If wallet credited, show additional info
        if (result['walletCredited'] == true) {
          AppSnackbar.showSuccess(
            title: 'Wallet Credited',
            message: '₹${result['walletBalance'] ?? 0} added to your wallet',
          );
        }
      } else {
        AppSnackbar.showError(
          title: 'Update Failed',
          message:
              result['message'] ?? 'Failed to update replacement pickup status',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to update replacement pickup status: $e',
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Select photo for upload
  void selectPhoto(File file) {
    selectedPhoto.value = file;
  }

  /// Clear selected photo
  void clearSelectedPhoto() {
    selectedPhoto.value = null;
  }

  /// Select return order
  void selectReturnOrder(ReturnOrder order) {
    selectedReturnOrder.value = order;
  }

  /// Refresh all return orders
  Future<void> refresh() async {
    await fetchReturnOrders();
  }
}
