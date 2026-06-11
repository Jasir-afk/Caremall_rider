import 'dart:io';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/src/modules/profile/controller/profile_repo.dart';
import 'package:care_mall_rider/src/modules/profile/model/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final RiderProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Personal
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  File? _selectedImage;

  // ── Payment
  late String _paymentMode;
  late TextEditingController _holderCtrl;
  late TextEditingController _accountCtrl;
  late TextEditingController _ifscCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _upiIdCtrl;
  late TextEditingController _upiNumberCtrl;

  // ── Vehicle
  late String _vehicleType;
  late TextEditingController _regCtrl;

  bool _loading = false;
  bool _removeAvatar = false;

  static const List<String> _vehicleOptions = [
    'Bike',
    'Car',
    'Half Lorry',
    'Truck',
  ];

  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _emailCtrl = TextEditingController(text: p.email);
    _addressCtrl = TextEditingController(text: p.address);
    _paymentMode = (p.paymentMode == 'upi') ? 'upi' : 'bank';
    _holderCtrl = TextEditingController(text: p.accountHolderName);
    _accountCtrl = TextEditingController(text: p.accountNumber);
    _ifscCtrl = TextEditingController(text: p.ifscCode);
    _bankNameCtrl = TextEditingController(text: p.bankName);
    _upiIdCtrl = TextEditingController(text: p.upiId);
    _upiNumberCtrl = TextEditingController(text: p.upiNumber);
    _vehicleType = _vehicleOptions.contains(p.vehicleType)
        ? p.vehicleType
        : _vehicleOptions.first;
    _regCtrl = TextEditingController(text: p.registrationNumber);
  }

  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _holderCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _bankNameCtrl.dispose();
    _upiIdCtrl.dispose();
    _upiNumberCtrl.dispose();
    _regCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    ImageSource? source;

    await showModalBottomSheet(
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
                text: 'Select Photo',
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
                  source = ImageSource.camera;
                  Navigator.pop(context);
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
                  source = ImageSource.gallery;
                  Navigator.pop(context);
                },
              ),
              if (_selectedImage != null || widget.profile.avatar.isNotEmpty)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFEBEE),
                    radius: 20.r,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[600],
                      size: 20.sp,
                    ),
                  ),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(fontSize: 16.sp, color: Colors.red[600]),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                      _removeAvatar = true;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source!, imageQuality: 90);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _removeAvatar = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppSnackbar.showError(
        title: 'Validation Error',
        message: 'Please fill all required fields correctly.',
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ProfileRepo.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        avatar: _selectedImage,
        paymentMode: _paymentMode,
        accountHolderName: _paymentMode == 'bank'
            ? _holderCtrl.text.trim()
            : null,
        accountNumber: _paymentMode == 'bank' ? _accountCtrl.text.trim() : null,
        ifscCode: _paymentMode == 'bank' ? _ifscCtrl.text.trim() : null,
        bankName: _paymentMode == 'bank' ? _bankNameCtrl.text.trim() : null,
        upiId: _paymentMode == 'upi' ? _upiIdCtrl.text.trim() : null,
        upiNumber: _paymentMode == 'upi' ? _upiNumberCtrl.text.trim() : null,
        vehicleType: _vehicleType,
        registrationNumber: _regCtrl.text.trim(),
        removeAvatar: _removeAvatar,
      );

      if (result['success'] == true) {
        // Update local storage so Home screen and others reflect the change
        final newName = _nameCtrl.text.trim();
        final newEmail = _emailCtrl.text.trim();
        final newAddress = _addressCtrl.text.trim();
        await StorageService.saveUserName(newName);
        await StorageService.saveUserEmail(newEmail);
        await StorageService.saveUserAddress(newAddress);

        // Save new avatar URL if available in response
        final data = result['data'];
        if (data != null) {
          final user =
              data['deliveryBoy'] ??
              data['rider'] ??
              data['user'] ??
              data['data'];
          if (user != null && user['avatar'] != null) {
            await StorageService.saveUserAvatar(user['avatar'].toString());
          }
          if (user != null && user['address'] != null) {
            await StorageService.saveUserAddress(user['address'].toString());
          }
        }

        Get.back(result: true);
        AppSnackbar.showSuccess(
          title: 'Success',
          message: 'Profile updated successfully!',
        );
      } else {
        AppSnackbar.showError(
          title: 'Error',
          message: result['message'] ?? 'Update failed',
        );
      }
    } catch (e) {
      AppSnackbar.showError(title: 'Error', message: 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Gradient Header ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Form Sections ────────────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 40.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionCard(
                    icon: SvgPicture.asset(
                      'assets/icons/user.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.primarycolor,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'Personal Info',
                    child: _buildPersonalSection(),
                  ),
                  SizedBox(height: 20.h),
                  _SectionCard(
                    icon: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primarycolor,
                    ),
                    title: 'Payment Setup',
                    child: _buildPaymentSection(),
                  ),
                  SizedBox(height: 20.h),
                  _SectionCard(
                    icon: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.primarycolor,
                    ),
                    title: 'Vehicle Details',
                    child: _buildVehicleSection(),
                  ),
                  SizedBox(height: 36.h),
                  _buildSaveButton(),
                  SizedBox(height: 12.h),
                  Center(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: AppText(
                        text: 'Discard Changes',
                        color: Colors.grey[500]!,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _buildDeleteAccountButton(),
                  SizedBox(height: 40.h),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    ImageProvider? imgProvider;
    if (_selectedImage != null) {
      imgProvider = FileImage(_selectedImage!);
    } else if (widget.profile.avatar.isNotEmpty) {
      imgProvider = NetworkImage(widget.profile.avatar);
    }
    final hasImage = imgProvider != null;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textnaturalcolor,
                    size: 20,
                  ),
                  onPressed: () => Get.back(),
                ),
                AppText(
                  text: 'Edit Profile',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textnaturalcolor,
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.white,
                    backgroundImage: _removeAvatar ? null : imgProvider,
                    child: (!hasImage || _removeAvatar)
                        ? SvgPicture.asset(
                            'assets/icons/user.svg',
                            width: 38.sp,
                            colorFilter: ColorFilter.mode(
                              Colors.grey[400]!,
                              BlendMode.srcIn,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(7.w),
                    decoration: BoxDecoration(
                      color: AppColors.primarycolor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ── Personal Section ──────────────────────────────────────────────────────

  Widget _buildPersonalSection() {
    return Column(
      children: [
        _EditField(
          label: 'Full Name',
          controller: _nameCtrl,
          icon: SvgPicture.asset(
            'assets/icons/user.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.primarycolor,
              BlendMode.srcIn,
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Name is required';
            if (v.trim().length < 3) {
              return 'Name must be at least 3 characters';
            }
            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) {
              return 'Enter a valid name (letters and spaces only)';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        _EditField(
          label: 'Email Address',
          controller: _emailCtrl,
          icon: SvgPicture.asset(
            'assets/icons/mail.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.primarycolor,
              BlendMode.srcIn,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        SizedBox(height: 16.h),
        _EditField(
          label: 'Address',
          controller: _addressCtrl,
          icon: const Icon(
            Icons.location_on_outlined,
            color: AppColors.primarycolor,
          ),
          hint: 'Enter your address',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Address is required';
            return null;
          },
        ),
      ],
    );
  }

  // ── Payment Section ───────────────────────────────────────────────────────

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              _ModeTab(
                label: '🏦  Bank Transfer',
                isSelected: _paymentMode == 'bank',
                onTap: () => setState(() => _paymentMode = 'bank'),
              ),
              _ModeTab(
                label: '📱  UPI',
                isSelected: _paymentMode == 'upi',
                onTap: () => setState(() => _paymentMode = 'upi'),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        if (_paymentMode == 'bank') ...[
          _EditField(
            label: 'Account Holder Name',
            controller: _holderCtrl,
            icon: const Icon(
              Icons.badge_outlined,
              color: AppColors.primarycolor,
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: 14.h),
          _EditField(
            label: 'Account Number',
            controller: _accountCtrl,
            icon: const Icon(
              Icons.account_balance_outlined,
              color: AppColors.primarycolor,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 9 || v.length > 18) {
                return 'Account number must be 9-18 digits';
              }
              return null;
            },
          ),
          SizedBox(height: 14.h),
          _EditField(
            label: 'IFSC Code',
            controller: _ifscCtrl,
            icon: const Icon(Icons.code_rounded, color: AppColors.primarycolor),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              _UpperCaseFormatter(),
            ],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: 14.h),
          _EditField(
            label: 'Bank Name',
            controller: _bankNameCtrl,
            icon: const Icon(
              Icons.business_rounded,
              color: AppColors.primarycolor,
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],

        if (_paymentMode == 'upi') ...[
          _EditField(
            label: 'UPI Registered Mobile',
            controller: _upiNumberCtrl,
            icon: SvgPicture.asset(
              'assets/icons/phone.svg',
              colorFilter: const ColorFilter.mode(
                AppColors.primarycolor,
                BlendMode.srcIn,
              ),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              return v.length < 10 ? 'Enter a valid 10-digit number' : null;
            },
          ),
          SizedBox(height: 14.h),
          _EditField(
            label: 'UPI ID (Optional)',
            controller: _upiIdCtrl,
            icon: const Icon(
              Icons.alternate_email_rounded,
              color: AppColors.primarycolor,
            ),
            keyboardType: TextInputType.emailAddress,
            hint: 'e.g. name@upi',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              // Permissive regex for UPI handles (allows numbers and dots)
              final upiRegex = RegExp(r'^[\w.\-]+@[a-zA-Z0-9.\-]+$');
              return upiRegex.hasMatch(v.trim())
                  ? null
                  : 'Enter a valid UPI ID (e.g. name@upi)';
            },
          ),
        ],

        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFBFD4FF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8.w),
              Expanded(
                child: AppText(
                  text:
                      'Payment details are encrypted and used only for delivery payouts.',
                  fontSize: 11.sp,
                  color: AppColors.textDefaultSecondarycolor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: 'Vehicle Type',
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600]!,
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _vehicleType,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primarycolor,
              ),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textnaturalcolor,
              ),
              items: _vehicleOptions.map((v) {
                const icons = {
                  'Bike': '🏍️',
                  'Car': '🚗',
                  'Half Lorry': '🚚',
                  'Truck': '🛻',
                };
                return DropdownMenuItem(
                  value: v,
                  child: Text('${icons[v] ?? '🚗'}  $v'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _vehicleType = v);
              },
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _EditField(
          label: 'Registration Number',
          controller: _regCtrl,
          icon: const Icon(
            Icons.confirmation_number_outlined,
            color: AppColors.primarycolor,
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
            _UpperCaseFormatter(),
          ],
          hint: 'e.g. KL01AB1234',
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _loading ? null : _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _loading ? Colors.grey[400] : AppColors.primarycolor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primarycolor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _loading
              ? SizedBox(
                  height: 24.h,
                  width: 24.h,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : AppText(
                  text: 'Save Changes',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  // ── Delete Account Button ─────────────────────────────────────────────────────

  Widget _buildDeleteAccountButton() {
    return GestureDetector(
      onTap: _loading ? null : _showDeleteConfirmation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56.h,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.shade50, Colors.red.shade100],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade700,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: 'Delete Account',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade800,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    text: 'This action cannot be undone',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red[600], size: 24.sp),
            SizedBox(width: 12.w),
            AppText(
              text: 'Delete Account',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textnaturalcolor,
            ),
          ],
        ),
        content: AppText(
          text:
              'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently removed.',
          fontSize: 14.sp,
          color: AppColors.textDefaultSecondarycolor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText(
              text: 'Cancel',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600] ?? Colors.grey,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: AppText(
              text: 'Delete',
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _loading = true);
    try {
      final result = await ProfileRepo.deleteAccount();

      if (result['success'] == true) {
        // Clear all locally stored authentication data
        await StorageService.clearAuthData();

        // Show success message
        if (mounted) {
          AppSnackbar.showSuccess(
            title: 'Account Deleted',
            message:
                result['message'] ??
                'Your account has been deleted successfully.',
          );

          // Redirect to login/signup screen
          Get.offAllNamed('/login');
        }
      } else {
        if (mounted) {
          AppSnackbar.showError(
            title: 'Deletion Failed',
            message: result['message'] ?? 'Failed to delete account.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          title: 'Error',
          message: 'Failed to delete account: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primarycolor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: SizedBox(width: 18.sp, height: 18.sp, child: icon),
              ),
              SizedBox(width: 10.w),
              AppText(
                text: title,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textnaturalcolor,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          child,
        ],
      ),
    );
  }
}

// ─── Editable Input Field ─────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Widget icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? hint;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.hint,
  });

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: label,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600]!,
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textnaturalcolor,
          ),
          decoration: InputDecoration(
            prefixIcon: Container(
              padding: EdgeInsets.all(12.w),
              child: SizedBox(width: 20.sp, height: 20.sp, child: icon),
            ),
            hintText: hint ?? 'Enter $label',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 16.h,
            ),
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.primarycolor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Payment Mode Tab ─────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: AppText(
              text: label,
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primarycolor
                  : AppColors.textDefaultSecondarycolor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Upper Case Formatter ─────────────────────────────────────────────────────

class _UpperCaseFormatter extends TextInputFormatter {
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
