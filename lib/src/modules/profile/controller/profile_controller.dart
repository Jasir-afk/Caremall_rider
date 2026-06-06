import 'dart:io';
import 'package:flutter/material.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/src/modules/profile/controller/profile_repo.dart';
import 'package:care_mall_rider/src/modules/profile/model/profile_model.dart';
import 'package:get/get.dart';

/// ProfileController manages all profile-related state and operations
class ProfileController extends GetxController {
  // Observable states
  final isLoading = false.obs;
  final isUpdating = false.obs;
  final errorMessage = Rxn<String>();

  // Profile data
  final profile = Rxn<RiderProfile>();

  // Form fields
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();

  // Payment fields
  final paymentMode = 'bank'.obs;
  final accountHolderNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ifscCodeController = TextEditingController();
  final bankNameController = TextEditingController();
  final upiIdController = TextEditingController();
  final upiNumberController = TextEditingController();

  // Vehicle fields
  final vehicleTypeController = TextEditingController();
  final registrationNumberController = TextEditingController();

  // Avatar
  final selectedAvatar = Rxn<File>();
  final removeAvatar = false.obs;

  void onInit() {
    super.onInit();
    fetchProfile();
  }

  void onClose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    phoneController.dispose();
    accountHolderNameController.dispose();
    accountNumberController.dispose();
    ifscCodeController.dispose();
    bankNameController.dispose();
    upiIdController.dispose();
    upiNumberController.dispose();
    vehicleTypeController.dispose();
    registrationNumberController.dispose();
    super.onClose();
  }

  /// Fetch rider profile from API
  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final response = await ProfileRepo.getProfile();
      profile.value = RiderProfile.fromJson(response);

      // Populate form fields
      _populateFormFields();
    } catch (e) {
      errorMessage.value = e.toString();
      // Check if it's a 401 error (session expired) or token not found
      if (e.toString().contains('401') ||
          e.toString().contains('Session expired') ||
          e.toString().contains('Authentication token not found') ||
          e.toString().contains('token')) {
        // Clear auth data and redirect to login silently
        await StorageService.clearAuthData();
        Get.offAllNamed('/login');
      } else {
        AppSnackbar.showError(
          title: 'Error',
          message: 'Failed to load profile: $e',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Populate form fields with current profile data
  void _populateFormFields() {
    final p = profile.value;
    if (p == null) return;

    nameController.text = p.name;
    emailController.text = p.email;
    addressController.text = p.address;
    phoneController.text = p.phone;

    paymentMode.value = p.paymentMode;
    accountHolderNameController.text = p.accountHolderName;
    accountNumberController.text = p.accountNumber;
    ifscCodeController.text = p.ifscCode;
    bankNameController.text = p.bankName;
    upiIdController.text = p.upiId;
    upiNumberController.text = p.upiNumber;

    vehicleTypeController.text = p.vehicleType;
    registrationNumberController.text = p.registrationNumber;
  }

  /// Update profile with new data
  Future<void> updateProfile() async {
    try {
      isUpdating.value = true;

      final result = await ProfileRepo.updateProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        avatar: selectedAvatar.value,
        paymentMode: paymentMode.value,
        accountHolderName: accountHolderNameController.text.trim(),
        accountNumber: accountNumberController.text.trim(),
        ifscCode: ifscCodeController.text.trim(),
        bankName: bankNameController.text.trim(),
        upiId: upiIdController.text.trim(),
        upiNumber: upiNumberController.text.trim(),
        vehicleType: vehicleTypeController.text.trim(),
        registrationNumber: registrationNumberController.text.trim(),
        removeAvatar: removeAvatar.value,
      );

      if (result['success'] == true) {
        AppSnackbar.showSuccess(
          title: 'Success',
          message: 'Profile updated successfully',
        );
        // Refresh profile data
        await fetchProfile();
        // Clear selected avatar
        selectedAvatar.value = null;
        removeAvatar.value = false;
      } else {
        AppSnackbar.showError(
          title: 'Update Failed',
          message: result['message'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to update profile: $e',
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Select avatar image
  void selectAvatar(File file) {
    selectedAvatar.value = file;
    removeAvatar.value = false;
  }

  /// Remove avatar
  void removeAvatarImage() {
    selectedAvatar.value = null;
    removeAvatar.value = true;
  }

  /// Change payment mode
  void changePaymentMode(String mode) {
    paymentMode.value = mode;
  }

  /// Logout user
  Future<void> logout() async {
    await StorageService.clearAuthData();
    Get.offAllNamed('/login');
  }
}
