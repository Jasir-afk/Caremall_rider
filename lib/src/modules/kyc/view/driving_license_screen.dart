import 'dart:io';
import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/src/modules/kyc/view/bank_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:care_mall_rider/app/utils/kyc_storage.dart';

class DrivingLicenseScreen extends StatefulWidget {
  const DrivingLicenseScreen({super.key});

  @override
  State<DrivingLicenseScreen> createState() => _DrivingLicenseScreenState();
}

class _DrivingLicenseScreenState extends State<DrivingLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _dobController = TextEditingController();
  final _expiryController = TextEditingController();

  File? _frontImage;
  File? _backImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _dobController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required bool isFront,
    required ImageSource source,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 50, // balanced quality
      maxWidth: 800, // force resize to reduce payload size massively
      maxHeight: 800,
    );
    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
        } else {
          _backImage = File(picked.path);
        }
      });
    }
  }

  void _showImageSourceSheet({required bool isFront}) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              AppText(
                text: isFront ? 'Upload Front Side' : 'Upload Back Side',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primarylightcolor,
                  radius: 20.r,
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primarycolor,
                    size: 20.sp,
                  ),
                ),
                title: Text('Take Photo', style: TextStyle(fontSize: 16.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isFront: isFront, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F0FE),
                  radius: 20.r,
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: const Color(0xFF4A6CF7),
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isFront: isFront, source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAndContinue() {
    if (_formKey.currentState!.validate()) {
      if (_frontImage == null || _backImage == null) {
        AppSnackbar.showError(
          title: 'Upload Required',
          message: 'Please upload both front and back of your license.',
        );
        return;
      }
      setState(() => _isLoading = true);
      // Save data locally
      KycStorage.saveDrivingLicense(
        licenseNumber: _licenseNumberController.text,
        dob: _dobController.text,
        expiryDate: _expiryController.text,
        frontImagePath: _frontImage?.path,
        backImagePath: _backImage?.path,
      );

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
          );
        }
      });
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
          text: 'Driving License',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textnaturalcolor,
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          children: [
            // ── Step Progress ──────────────────────────────────────────
            _StepProgressBar(currentStep: 1, totalSteps: 3),
            SizedBox(height: 22.h),

            // ── Section Title ──────────────────────────────────────────
            AppText(
              text: 'Driving License',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textnaturalcolor,
            ),
            SizedBox(height: 4.h),
            AppText(
              text: 'Upload front and back of your driving license',
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textDefaultSecondarycolor,
            ),
            SizedBox(height: 20.h),

            // ── Image Upload Row ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ImageUploadBox(
                    label: 'Front Side',
                    image: _frontImage,
                    onTap: () => _showImageSourceSheet(isFront: true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _ImageUploadBox(
                    label: 'Back Side',
                    image: _backImage,
                    onTap: () => _showImageSourceSheet(isFront: false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // ── Take Photo with Camera ─────────────────────────────────
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.primarycolor,
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 13.h),
                backgroundColor: AppColors.primarylightcolor,
              ),
              icon: Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primarycolor,
                size: 20.sp,
              ),
              label: AppText(
                text: 'Take Photo with Camera',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primarycolor,
              ),
              onPressed: () => _showImageSourceSheet(isFront: true),
            ),
            SizedBox(height: 20.h),

            const _TipsCard(),
            SizedBox(height: 28.h),

            // ── Save & Continue ────────────────────────────────────────
            AppButton(
              isLoading: _isLoading,
              borderRadius: 30.r,
              onPressed: () {
                HapticFeedback.selectionClick();
                _saveAndContinue();
              },
              child: AppText(
                text: 'Save & Continue',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.whitecolor,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
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
      final bool isCurrent = index == currentStep - 1;

      // Circle
      children.add(
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primarycolor : const Color(0xFFE0E0E0),
          ),
          child: Center(
            child: AppText(
              text: '${index + 1}',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? Colors.white
                  : AppColors.textDefaultSecondarycolor,
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
              color: isCurrent || index < currentStep - 1
                  ? AppColors.primarycolor.withValues(alpha: 0.3)
                  : const Color(0xFFE0E0E0),
            ),
          ),
        );
      }
    }

    return Row(children: children);
  }
}

// ─── Image Upload Box ──────────────────────────────────────────────────────────
class _ImageUploadBox extends StatelessWidget {
  final String label;
  final File? image;
  final VoidCallback onTap;

  const _ImageUploadBox({
    required this.label,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFCCCCCC),
            width: 1.5,
            // dashed effect via BoxBorder not natively available; using solid with low opacity
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11.r),
                child: Image.file(image!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_outlined,
                    size: 28.sp,
                    color: const Color(0xFF4A6CF7),
                  ),
                  SizedBox(height: 8.h),
                  AppText(
                    text: label,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textnaturalcolor,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    text: 'Tap to upload',
                    fontSize: 11.sp,
                    color: AppColors.textDefaultSecondarycolor,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Tips Card ─────────────────────────────────────────────────────────────────
class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Ensure all text is clearly visible',
      'No glare or shadows on the document',
      'Place document on a flat, dark surface',
      'All four corners must be visible',
    ];

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFBFD4FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 6.w),
              AppText(
                text: 'Tips for better upload',
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A6CF7),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...tips.map(
            (tip) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textDefaultSecondarycolor,
                    ),
                  ),
                  Expanded(
                    child: AppText(
                      text: tip,
                      fontSize: 12.sp,
                      color: AppColors.textDefaultSecondarycolor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
