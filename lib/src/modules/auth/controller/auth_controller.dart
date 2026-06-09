import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/src/modules/auth/controller/auth_repo.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

/// Authentication Controller using GetX for state management
/// Handles all authentication-related business logic
class AuthController extends GetxController {
  // Observable states
  final isLoading = false.obs;
  final isResendingOtp = false.obs;

  // User data
  final phoneNumber = ''.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userAvatar = ''.obs;
  final authToken = ''.obs;
  final isOnline = false.obs;

  void onInit() {
    super.onInit();
    // Restore authentication state from persistent storage on startup
    _restoreAuthState();
  }

  /// Restore authentication state from SharedPreferences
  Future<void> _restoreAuthState() async {
    final savedToken = await StorageService.getAuthToken();
    final savedPhone = await StorageService.getPhoneNumber();
    final savedName = await StorageService.getUserName();
    final savedEmail = await StorageService.getUserEmail();
    final savedAvatar = await StorageService.getUserAvatar();
    final savedOnlineStatus = await StorageService.getOnlineStatus();

    if (savedToken != null) authToken.value = savedToken;
    if (savedPhone != null) phoneNumber.value = savedPhone;
    if (savedName != null) userName.value = savedName;
    if (savedEmail != null) userEmail.value = savedEmail;
    if (savedAvatar != null) userAvatar.value = savedAvatar;
    if (savedOnlineStatus != null) isOnline.value = savedOnlineStatus;

    // Fetch online status from server if user is logged in
    if (authToken.value.isNotEmpty) {
      await fetchOnlineStatus();
    }
  }

  /// Sends OTP for login
  ///
  /// Parameters:
  /// - [phone]: 10-digit phone number
  /// - [onSuccess]: Callback function when OTP is sent successfully
  /// - [onError]: Callback function when there's an error
  Future<void> sendLoginOtp({
    required String phone,
    Function? onSuccess,
    Function(String)? onError,
  }) async {
    isLoading.value = true;

    try {
      final result = await AuthRepo.sendOtp(phone: phone, mode: 'login');

      if (result['success']) {
        phoneNumber.value = phone;
        AppSnackbar.showSuccess(title: 'Success', message: result['message']);
        if (onSuccess != null) onSuccess();
      } else {
        AppSnackbar.showError(title: 'Error', message: result['message']);
        if (onError != null) onError(result['message']);
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to send OTP: ${e.toString()}',
      );
      if (onError != null) onError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Sends OTP for signup/registration
  ///
  /// Parameters:
  /// - [phone]: 10-digit phone number
  /// - [name]: User's full name
  /// - [email]: User's email address
  /// - [onSuccess]: Callback function when OTP is sent successfully
  /// - [onError]: Callback function when there's an error
  Future<void> sendSignupOtp({
    required String phone,
    required String name,
    required String email,
    Function? onSuccess,
    Function(String)? onError,
  }) async {
    isLoading.value = true;

    try {
      final result = await AuthRepo.sendOtp(
        phone: phone,
        mode: 'signup',
        name: name,
        email: email,
      );

      if (result['success']) {
        phoneNumber.value = phone;
        userName.value = name;
        userEmail.value = email;
        AppSnackbar.showSuccess(title: 'Success', message: result['message']);
        if (onSuccess != null) onSuccess();
      } else {
        AppSnackbar.showError(title: 'Error', message: result['message']);
        if (onError != null) onError(result['message']);
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to send OTP: ${e.toString()}',
      );
      if (onError != null) onError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies the OTP entered by user
  ///
  /// Parameters:
  /// - [phone]: 10-digit phone number
  /// - [otp]: 6-digit OTP code
  /// - [onSuccess]: Callback function when OTP is verified successfully
  /// - [onError]: Callback function when there's an error
  Future<void> verifyOtp({
    required String phone,
    required String otp,
    Function? onSuccess,
    Function(String)? onError,
  }) async {
    isLoading.value = true;

    try {
      final result = await AuthRepo.verifyOtp(phone: phone, otp: otp);
      if (kDebugMode) {
        print("FULL RESPONSE: $result");
      }
      if (kDebugMode) {
        print("TOKEN IS: ${result['token']}");
      }

      if (result['success']) {
        // Save authentication token if provided
        // Save authentication token if provided
        if (result['token'] != null) {
          authToken.value = result['token'];
          // Save token to persistent storage
          await StorageService.saveAuthToken(result['token']);
        }

        // Save user details if provided
        if (result['user'] != null) {
          final userData = result['user'];
          if (userData['name'] != null) {
            userName.value = userData['name'];
            await StorageService.saveUserName(userData['name']);
          }
          if (userData['email'] != null) {
            userEmail.value = userData['email'];
            await StorageService.saveUserEmail(userData['email']);
          }
          if (userData['avatar'] != null) {
            userAvatar.value = userData['avatar'];
            await StorageService.saveUserAvatar(userData['avatar']);
          }
          // Phone is already passed to the function, but good to save it from response if available and consistent
          // However, the phone arg is the one used for OTP, so we stick with it or update if response has it.
          // The response has phone as number, we treat as string.
          if (userData['phone'] != null) {
            final phoneStr = userData['phone'].toString();
            phoneNumber.value = phoneStr;
            await StorageService.savePhoneNumber(phoneStr);
          } else {
            phoneNumber.value = phone;
            await StorageService.savePhoneNumber(phone);
          }
        } else {
          phoneNumber.value = phone;
          await StorageService.savePhoneNumber(phone);
        }

        AppSnackbar.showSuccess(title: 'Success', message: result['message']);
        if (onSuccess != null) onSuccess();
      } else {
        AppSnackbar.showError(title: 'Error', message: result['message']);
        if (onError != null) onError(result['message']);
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to verify OTP: ${e.toString()}',
      );
      if (onError != null) onError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Resends OTP using stored user data
  ///
  /// Parameters:
  /// - [mode]: "login" or "signup"
  /// - [onSuccess]: Callback function when OTP is sent successfully
  /// - [onError]: Callback function when there's an error
  Future<void> resendOtp({
    required String mode,
    Function? onSuccess,
    Function(String)? onError,
  }) async {
    isResendingOtp.value = true;

    try {
      final result = await AuthRepo.sendOtp(
        phone: phoneNumber.value,
        mode: mode,
        name: mode == 'signup' ? userName.value : '',
        email: mode == 'signup' ? userEmail.value : '',
      );

      if (result['success']) {
        AppSnackbar.showSuccess(title: 'Success', message: result['message']);
        if (onSuccess != null) onSuccess();
      } else {
        AppSnackbar.showError(title: 'Error', message: result['message']);
        if (onError != null) onError(result['message']);
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to resend OTP: ${e.toString()}',
      );
      if (onError != null) onError(e.toString());
    } finally {
      isResendingOtp.value = false;
    }
  }

  /// Clears all authentication data
  Future<void> logout() async {
    phoneNumber.value = '';
    userName.value = '';
    userEmail.value = '';
    userAvatar.value = '';
    authToken.value = '';
    isOnline.value = false;
    isLoading.value = false;
    isResendingOtp.value = false;
    // Clear persistent storage
    await StorageService.clearAuthData();
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    return await StorageService.isLoggedIn();
  }

  /// Fetches the rider's current online status from server
  Future<void> fetchOnlineStatus() async {
    if (authToken.value.isEmpty) return;

    try {
      final result = await AuthRepo.getOnlineStatus(token: authToken.value);

      if (result['success'] && result['data'] != null) {
        final bool serverOnlineStatus = result['data']['isOnline'] ?? false;
        isOnline.value = serverOnlineStatus;
        // Save to persistent storage
        await StorageService.saveOnlineStatus(serverOnlineStatus);
      }
    } catch (e) {
      // Silently fail - use cached status if fetch fails
      if (kDebugMode) {
        print('Failed to fetch online status: ${e.toString()}');
      }
    }
  }

  /// Toggles the rider's online status
  ///
  /// Parameters:
  /// - [onSuccess]: Callback function when status is toggled successfully
  /// - [onError]: Callback function when there's an error
  Future<void> toggleOnlineStatus({
    Function? onSuccess,
    Function(String)? onError,
  }) async {
    isLoading.value = true;

    try {
      final result = await AuthRepo.toggleOnlineStatus(
        isOnline: !isOnline.value,
        token: authToken.value,
      );

      if (result['success']) {
        // Update the online status
        isOnline.value = !isOnline.value;
        // Save to persistent storage
        await StorageService.saveOnlineStatus(isOnline.value);

        AppSnackbar.showSuccess(title: 'Success', message: result['message']);
        if (onSuccess != null) onSuccess();
      } else {
        AppSnackbar.showError(title: 'Error', message: result['message']);
        if (onError != null) onError(result['message']);
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to update status: ${e.toString()}',
      );
      if (onError != null) onError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
