import 'dart:io';
import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';

import 'package:care_mall_rider/src/modules/home_screen/view/home_screen.dart';
import 'package:care_mall_rider/src/modules/kyc/controller/kyc_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:care_mall_rider/app/utils/kyc_storage.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  int? _selectedVehicleIndex;
  bool _isLoading = false;
  final _registrationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<_VehicleModel> _vehicles = [
    _VehicleModel(
      title: 'Bike',
      description: 'Small parcel ',
      limit: 'Up to 10 kg',
      price: '₹8-15/km',
      icon: Icons.two_wheeler,
      color: const Color(0xFFFFF0F0),
      iconColor: Colors.red,
      limitColor: const Color(0xFFE8F0FE),
      limitTextColor: const Color(0xFF4A6CF7),
      priceColor: const Color(0xFFFFE8E8),
      priceTextColor: Colors.red,
    ),
    _VehicleModel(
      title: 'Car',
      description: 'Medium parcels & goods',
      limit: 'Up to 50 kg',
      price: '₹15-25/km',
      icon: Icons.local_taxi,
      color: const Color(0xFFE8F0FE),
      iconColor: const Color(0xFF4A6CF7),
      limitColor: const Color(0xFFF3E5F5),
      limitTextColor: Colors.purple,
      priceColor: const Color(0xFFFFE8E8),
      priceTextColor: Colors.red,
    ),
    _VehicleModel(
      title: 'Pickup Van',
      description: 'Large packages',
      limit: 'Up to 500 kg',
      price: '₹25-40/km',
      icon: Icons.local_shipping,
      color: const Color(0xFFF3E5F5),
      iconColor: Colors.purple,
      limitColor: const Color(0xFFFFF3E0),
      limitTextColor: Colors.orange,
      priceColor: const Color(0xFFFFE8E8),
      priceTextColor: Colors.red,
    ),
    _VehicleModel(
      title: 'Truck',
      description: 'Heavy & bulk cargo',
      limit: 'Up to 2000 kg',
      price: '₹40-60/km',
      icon: Icons.local_shipping,
      color: const Color(0xFFE8F5E9),
      iconColor: Colors.green,
      limitColor: const Color(0xFFE0F2F1),
      limitTextColor: Colors.teal,
      priceColor: const Color(0xFFFFE8E8),
      priceTextColor: Colors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _registrationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedVehicleIndex != null &&
      _registrationController.text.trim().isNotEmpty;

  void _submitVerification() async {
    if (_selectedVehicleIndex == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Save vehicle selection locally
    KycStorage.saveVehicleSelection(
      vehicleIndex: _selectedVehicleIndex!,
      vehicleTitle: _vehicles[_selectedVehicleIndex!].title,
    );

    // Read all locally stored KYC data
    final licenseData = await KycStorage.getDrivingLicense();
    final bankData = await KycStorage.getBankDetails();

    // Prepare files
    File? drivingLicenseFront;
    File? drivingLicenseBack;

    if (licenseData != null) {
      if (licenseData['frontImagePath'] != null) {
        drivingLicenseFront = File(licenseData['frontImagePath']);
        if (drivingLicenseFront.existsSync() &&
            drivingLicenseFront.lengthSync() > 2500000) {
          setState(() => _isLoading = false);
          AppSnackbar.showError(
            title: 'Image Too Large',
            message:
                'Your Front image is too large. Please go back to the Driving License step and re-take the photo.',
          );
          return;
        }
      }
      if (licenseData['backImagePath'] != null) {
        drivingLicenseBack = File(licenseData['backImagePath']);
        if (drivingLicenseBack.existsSync() &&
            drivingLicenseBack.lengthSync() > 2500000) {
          setState(() => _isLoading = false);
          AppSnackbar.showError(
            title: 'Image Too Large',
            message:
                'Your Back image is too large. Please go back to the Driving License step and re-take the photo.',
          );
          return;
        }
      }
    }

    // Call the API
    final result = await KycRepo.submitKyc(
      vehicleType: _vehicles[_selectedVehicleIndex!].title,
      registrationNumber: _registrationController.text.trim(),
      licenseNumber: licenseData?['licenseNumber'] ?? '',
      dob: licenseData?['dob'] ?? '',
      expiryDate: licenseData?['expiryDate'] ?? '',
      drivingLicenceFront: drivingLicenseFront,
      drivingLicenceBack: drivingLicenseBack,
      paymentMode: bankData?['paymentMode'] ?? 'bank',
      accountHolderName: bankData?['accountHolderName'] ?? '',
      accountNumber: bankData?['accountNumber'] ?? '',
      ifscCode: bankData?['ifscCode'] ?? '',
      bankName: bankData?['bankName'] ?? '',
      upiId: bankData?['upiId'] ?? '',
      upiNumber: bankData?['upiNumber'] ?? '',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Mark KYC as completed in persistent storage
      await StorageService.saveKycCompleted(true);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      AppSnackbar.showSuccess(
        title: 'Application Submitted!',
        message: result['message'] ?? 'Your application is being processed.',
      );
    } else {
      final message = result['message']?.toString() ?? '';
      if (message.contains('KYC already approved')) {
        // Correct the status and move home
        await StorageService.saveKycStatus('approved');
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        AppSnackbar.showSuccess(
          title: 'Already Verified',
          message: 'Your account is already verified. Redirecting to home...',
        );
      } else {
        AppSnackbar.showError(
          title: 'BACKEND REJECTED',
          message: 'DEV_LOG: ${result.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: Colors.black,
            ),
          ),
        ),
        title: AppText(
          text: 'Vehicle Selection',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textnaturalcolor,
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                children: [
                  // ── Step Progress ──────────────────────────────────────────
                  const _StepProgressBar(currentStep: 3, totalSteps: 3),
                  SizedBox(height: 22.h),

                  // ── Section Title ──────────────────────────────────────────
                  AppText(
                    text: 'Select Your Vehicle',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textnaturalcolor,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    text: 'Choose the vehicle type you\'ll use for deliveries',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textDefaultSecondarycolor,
                  ),
                  SizedBox(height: 20.h),

                  // ── Registration Number ────────────────────────────────
                  AppText(
                    text: 'Vehicle Registration Number',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textnaturalcolor,
                  ),
                  SizedBox(height: 6.h),
                  _InputField(
                    controller: _registrationController,
                    hint: 'e.g. KL 01 AB 1234',
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9 ]'),
                      ),
                      _UpperCaseFormatter(),
                    ],
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter registration number'
                        : null,
                  ),
                  SizedBox(height: 20.h),

                  // ── Vehicle List ───────────────────────────────────────────
                  ...List.generate(_vehicles.length, (index) {
                    final vehicle = _vehicles[index];
                    final isSelected = _selectedVehicleIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _VehicleCard(
                        vehicle: vehicle,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedVehicleIndex = index);
                        },
                      ),
                    );
                  }),
                  SizedBox(height: 8.h),
                ],
              ),
            ),

            // ── Bottom Button ──────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: AppButton(
                isLoading: _isLoading,
                borderRadius: 30.r,
                onPressed: _canSubmit ? _submitVerification : null,
                btncolor: _canSubmit
                    ? AppColors.primarycolor
                    : Colors.grey[300],
                child: AppText(
                  text: 'Submit for Verification',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _canSubmit
                      ? AppColors.whitecolor
                      : Colors.grey[600] ?? Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleModel {
  final String title;
  final String description;
  final String limit;
  final String price;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final Color limitColor;
  final Color limitTextColor;
  final Color priceColor;
  final Color priceTextColor;

  _VehicleModel({
    required this.title,
    required this.description,
    required this.limit,
    required this.price,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.limitColor,
    required this.limitTextColor,
    required this.priceColor,
    required this.priceTextColor,
  });
}

class _VehicleCard extends StatelessWidget {
  final _VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primarycolor : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primarycolor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Vehicle Icon
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: vehicle.color,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(vehicle.icon, color: vehicle.iconColor, size: 30.sp),
            ),
            SizedBox(width: 16.w),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: vehicle.title,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textnaturalcolor,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    text: vehicle.description,
                    fontSize: 12.sp,
                    color: AppColors.textDefaultSecondarycolor,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      _Tag(
                        text: vehicle.limit,
                        bgColor: vehicle.limitColor,
                        textColor: vehicle.limitTextColor,
                      ),
                      SizedBox(width: 8.w),
                      _Tag(
                        text: vehicle.price,
                        bgColor: vehicle.priceColor,
                        textColor: vehicle.priceTextColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _Tag({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: AppText(
        text: text,
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

// ─── Step Progress Bar ─────────────────────────────────────────────────────────
class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    for (int index = 0; index < totalSteps; index++) {
      final bool isActive = index < currentStep;
      final bool isCompleted =
          index < currentStep - 1; // Completed steps are checked
      final bool isCurrent = index == currentStep - 1;

      // Circle
      children.add(
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCurrent
                ? AppColors.primarycolor
                : const Color(0xFFE0E0E0),
          ),
          child: Center(
            child: isActive
                ? (isCompleted
                      ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                      : AppText(
                          text: '${index + 1}',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ))
                : AppText(
                    text: '${index + 1}',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDefaultSecondarycolor,
                  ),
          ),
        ),
      );

      // Line (except after last)
      if (index < totalSteps - 1) {
        children.add(
          Expanded(
            child: Container(
              height: 2.h,
              color: isActive
                  ? AppColors
                        .primarycolor // Active line if previous step is active
                  : const Color(0xFFE0E0E0),
            ),
          ),
        );
      }
    }

    return Row(children: children);
  }
}

// ─── Reusable Input Field ──────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.hint,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(
            color: AppColors.primarycolor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Upper Case Formatter ──────────────────────────────────────────────────────
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
