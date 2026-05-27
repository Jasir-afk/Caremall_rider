import 'package:care_mall_rider/app/utils/network/logger_service.dart';
import 'package:get/get.dart';
import 'package:care_mall_rider/src/modules/wallet/controller/wallet_repo.dart';
import 'package:care_mall_rider/src/modules/wallet/model/wallet_model.dart';
import 'package:care_mall_rider/src/modules/wallet/model/withdrawal_request_model.dart';
import 'package:care_mall_rider/src/modules/wallet/view/withdrawal_success_screen.dart';

import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';

class WalletController extends GetxController {
  var isLoading = false.obs;
  var walletData = Rxn<WalletModel>();
  var withdrawalRequests = <WithdrawalRequest>[].obs;
  var errorMessage = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchWalletData();
    fetchWithdrawalRequests();
  }

  Future<void> fetchWalletData() async {
    try {
      isLoading(true);
      errorMessage.value = null;
      final data = await WalletRepo.getWalletData();
      walletData.value = data;
    } catch (e) {
      errorMessage.value =
          'Could not load wallet. Please check your connection and try again.';
      Log.error('Error fetching wallet data', error: e);
    } finally {
      isLoading(false);
    }
  }

  Future<void> requestWithdrawal(num amount) async {
    try {
      isLoading(true);
      final result = await WalletRepo.requestWithdrawal(amount);
      if (result['success']) {
        Get.back(); // Close bottom sheet
        Get.to(() => WithdrawalSuccessScreen(amount: amount));
        // Refresh both wallet balance and withdrawal request list
        await Future.wait([
          fetchWalletData(),
          fetchWithdrawalRequests(),
        ]);
      } else {
        AppSnackbar.showError(
          title: 'Error',
          message: result['message'] ?? 'Failed to request withdrawal',
        );
      }
    } catch (e) {
      AppSnackbar.showError(title: 'Error', message: 'An error occurred: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Refresh all wallet data — used by pull-to-refresh and on screen resume
  /// so that accepted/processed withdrawals are reflected immediately.
  Future<void> refreshAll() async {
    await Future.wait([
      fetchWalletData(),
      fetchWithdrawalRequests(),
    ]);
  }

  Future<void> fetchWithdrawalRequests() async {
    try {
      final requests = await WalletRepo.getWithdrawalRequests();
      withdrawalRequests.assignAll(requests);
    } catch (e) {
      // Optional: Handle error silently or show snackbar if important
      Log.error('Error fetching withdrawal requests', error: e);
    }
  }
}
