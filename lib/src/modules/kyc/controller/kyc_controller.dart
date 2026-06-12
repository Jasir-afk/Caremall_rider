import 'dart:io';
import 'package:flutter/material.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/src/modules/kyc/controller/kyc_repo.dart';
import 'package:get/get.dart';

/// KYCController manages KYC verification flow and state
class KYCController extends GetxController {
  // Observable states
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final kycStatus = 'pending'.obs;
  final errorMessage = Rxn<String>();

  // Step tracking: 0=Vehicle, 1=Driving License, 2=Bank Details
  final currentStep = 0.obs;
  final totalSteps = 3;

  // Vehicle details
  final vehicleType = ''.obs;
  final registrationNumber = TextEditingController();

  // Driving license details
  final licenseNumber = TextEditingController();
  final dob = TextEditingController();
  final expiryDate = TextEditingController();
  final drivingLicenceFront = Rxn<File>();
  final drivingLicenceBack = Rxn<File>();

  // Bank/UPI details
  final paymentMode = 'bank'.obs;
  final accountHolderName = TextEditingController();
  final accountNumber = TextEditingController();
  final ifscCode = TextEditingController();
  final bankName = TextEditingController();
  final upiId = TextEditingController();
  final upiNumber = TextEditingController();

  void onInit() {
    super.onInit();
    fetchKycStatus();
  }

  void onClose() {
    registrationNumber.dispose();
    licenseNumber.dispose();
    dob.dispose();
    expiryDate.dispose();
    accountHolderName.dispose();
    accountNumber.dispose();
    ifscCode.dispose();
    bankName.dispose();
    upiId.dispose();
    upiNumber.dispose();
    super.onClose();
  }

  /// Fetch current KYC status from API
  Future<void> fetchKycStatus() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final result = await KycRepo.getKycStatus();
      if (result['success'] == true) {
        kycStatus.value = result['status'] ?? 'pending';
      } else {
        errorMessage.value = result['message'];
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit KYC data
  Future<void> submitKyc() async {
    try {
      isSubmitting.value = true;

      final result = await KycRepo.submitKyc(
        vehicleType: vehicleType.value,
        registrationNumber: registrationNumber.text.trim(),
        licenseNumber: licenseNumber.text.trim(),
        dob: dob.text.trim(),
        expiryDate: expiryDate.text.trim(),
        drivingLicenceFront: drivingLicenceFront.value,
        drivingLicenceBack: drivingLicenceBack.value,
        paymentMode: paymentMode.value,
        accountHolderName: accountHolderName.text.trim(),
        accountNumber: accountNumber.text.trim(),
        ifscCode: ifscCode.text.trim(),
        bankName: bankName.text.trim(),
        upiId: upiId.text.trim(),
        upiNumber: upiNumber.text.trim(),
      );

      if (result['success'] == true) {
        AppSnackbar.showSuccess(
          title: 'KYC Submitted',
          message:
              result['message'] ??
              'Your KYC has been submitted for verification',
        );
        kycStatus.value = 'under_review';
        Get.back(); // Navigate back
      } else {
        AppSnackbar.showError(
          title: 'Submission Failed',
          message: result['message'] ?? 'Failed to submit KYC',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        title: 'Error',
        message: 'Failed to submit KYC: $e',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Navigate to next step
  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    }
  }

  /// Navigate to previous step
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      currentStep.value = step;
    }
  }

  /// Select vehicle type
  void selectVehicleType(String type) {
    vehicleType.value = type;
  }

  /// Select driving license front image
  void selectDrivingLicenceFront(File file) {
    drivingLicenceFront.value = file;
  }

  /// Select driving license back image
  void selectDrivingLicenceBack(File file) {
    drivingLicenceBack.value = file;
  }

  /// Change payment mode
  void changePaymentMode(String mode) {
    paymentMode.value = mode;
  }

  /// Check if KYC is approved
  bool get isKycApproved =>
      kycStatus.value == 'approved' || kycStatus.value == 'verified';

  /// Check if KYC is under review
  bool get isKycUnderReview => kycStatus.value == 'under_review';

  /// Check if KYC is rejected
  bool get isKycRejected => kycStatus.value == 'rejected';

  /// Check if KYC is pending
  bool get isKycPending => kycStatus.value == 'pending';
}
