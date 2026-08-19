import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // Track state to avoid redundant snackbars
  bool _wasOffline = false;

  @override
  void onInit() {
    super.onInit();
    _checkInitialStatus();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _checkInitialStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results, isInitial: true);
    } catch (e) {
      Get.log("Connectivity check failed: $e");
    }
  }

  void _updateConnectionStatus(
    List<ConnectivityResult> results, {
    bool isInitial = false,
  }) {
    final bool hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hasConnection) {
      // Only show offline snackbar if we weren't already offline (or if it's the initial check and we're offline)
      if (!_wasOffline || isInitial) {
        _wasOffline = true;
        AppSnackbar.showError(
          title: 'Offline',
          message:
              'You are currently offline. Please check your internet connection.',
        );
      }
    } else {
      // If we were offline and now we have a connection
      if (_wasOffline) {
        _wasOffline = false;
        AppSnackbar.showSuccess(
          title: 'Online',
          message: 'Your internet connection has been restored.',
        );
      }
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
