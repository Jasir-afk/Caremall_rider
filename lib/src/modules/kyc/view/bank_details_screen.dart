import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/app/utils/spaces.dart';
import 'package:care_mall_rider/app/utils/kyc_storage.dart';
import 'package:care_mall_rider/src/modules/kyc/view/vehicle_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  String _paymentMode = 'bank';

  // Bank controllers
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();

  // UPI controllers
  final _upiNumberController = TextEditingController();
  final _upiIdController = TextEditingController();

  // Visibility toggles
  bool _obscureAccount = true;
  bool _obscureConfirmAccount = true;

  bool _isLoading = false;

  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _upiNumberController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await KycStorage.saveBankDetails(
        paymentMode: _paymentMode,
        accountHolderName: _accountHolderController.text,
        accountNumber: _accountNumberController.text,
        ifscCode: _ifscController.text,
        bankName: _bankNameController.text,
        upiId: _upiIdController.text,
        upiNumber: _upiNumberController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VehicleSelectionScreen()),
      );
    }
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateAccountHolderName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Account holder name is required';
    if (v.trim().length < 3) return 'Name must be at least 3 characters';
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(v.trim())) {
      return 'Name should contain only letters and spaces';
    }
    return null;
  }

  String? _validateAccountNumber(String? v) {
    if (v == null || v.isEmpty) return 'Account number is required';
    if (v.length < 9) return 'Account number must be at least 9 digits';
    if (v.length > 18) return 'Account number must be at most 18 digits';
    return null;
  }

  String? _validateConfirmAccountNumber(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your account number';
    if (v != _accountNumberController.text) {
      return 'Account numbers do not match';
    }
    return null;
  }

  String? _validateIFSC(String? v) {
    if (v == null || v.trim().isEmpty) return 'IFSC code is required';
    // Indian IFSC format: 4 letters + 0 + 6 alphanumeric
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(v.trim().toUpperCase())) {
      return 'Invalid IFSC format (e.g. SBIN0001234)';
    }
    return null;
  }

  String? _validateBankName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Bank name is required';
    if (v.trim().length < 3) return 'Enter a valid bank name';
    return null;
  }

  String? _validateUpiMobile(String? v) {
    if (v == null || v.isEmpty) return 'Mobile number is required';
    if (v.length != 10) return 'Enter a valid 10-digit mobile number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      return 'Enter a valid Indian mobile number starting with 6-9';
    }
    return null;
  }

  String? _validateUpiId(String? v) {
    if (v == null || v.isEmpty) return null; // optional
    final upiRegex = RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$');
    if (!upiRegex.hasMatch(v)) {
      return 'Invalid UPI ID format (e.g. name@upi, 9876543210@paytm)';
    }
    return null;
  }

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
          text: 'Bank Details',
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
            _StepProgressBar(currentStep: 2, totalSteps: 3),
            SizedBox(height: 22.h),

            AppText(
              text: 'Payment Details',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textnaturalcolor,
            ),
            SizedBox(height: 4.h),
            AppText(
              text: 'Add your bank or UPI details for payouts',
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textDefaultSecondarycolor,
            ),
            SizedBox(height: 24.h),

            // ── Payment Mode Toggle ──────────────────────────────────
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  _ModeTab(
                    label: 'Bank Transfer',
                    isSelected: _paymentMode == 'bank',
                    onTap: () {
                      setState(() => _paymentMode = 'bank');
                      _formKey.currentState?.reset();
                    },
                  ),
                  _ModeTab(
                    label: 'UPI',
                    isSelected: _paymentMode == 'upi',
                    onTap: () {
                      setState(() => _paymentMode = 'upi');
                      _formKey.currentState?.reset();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // ── Bank Fields ──────────────────────────────────────────
            if (_paymentMode == 'bank') ...[
              _FieldLabel(text: 'Account Holder Name'),
              defaultSpacerSmall,
              _InputField(
                controller: _accountHolderController,
                hint: 'Enter full name as per bank records',
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                validator: _validateAccountHolderName,
              ),
              SizedBox(height: 16.h),

              _FieldLabel(text: 'Account Number'),
              defaultSpacerSmall,
              _InputField(
                controller: _accountNumberController,
                hint: 'Enter account number',
                keyboardType: TextInputType.number,
                obscureText: _obscureAccount,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(18),
                ],
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureAccount
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20.sp,
                    color: AppColors.textDefaultSecondarycolor,
                  ),
                  onPressed: () =>
                      setState(() => _obscureAccount = !_obscureAccount),
                ),
                validator: _validateAccountNumber,
              ),
              SizedBox(height: 16.h),

              _FieldLabel(text: 'Confirm Account Number'),
              defaultSpacerSmall,
              _InputField(
                controller: _confirmAccountNumberController,
                hint: 'Re-enter account number',
                keyboardType: TextInputType.number,
                obscureText: _obscureConfirmAccount,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(18),
                ],
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmAccount
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20.sp,
                    color: AppColors.textDefaultSecondarycolor,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmAccount = !_obscureConfirmAccount,
                  ),
                ),
                validator: _validateConfirmAccountNumber,
              ),
              SizedBox(height: 16.h),

              _FieldLabel(text: 'IFSC Code'),
              defaultSpacerSmall,
              _InputField(
                controller: _ifscController,
                hint: 'e.g. SBIN0001234',
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(11),
                  _UpperCaseFormatter(),
                ],
                validator: _validateIFSC,
              ),
              SizedBox(height: 16.h),

              _FieldLabel(text: 'Bank Name'),
              defaultSpacerSmall,
              _InputField(
                controller: _bankNameController,
                hint: 'e.g. State Bank of India',
                textCapitalization: TextCapitalization.words,
                validator: _validateBankName,
              ),
            ],

            // ── UPI Fields ───────────────────────────────────────────
            if (_paymentMode == 'upi') ...[
              _FieldLabel(text: 'UPI Registered Mobile Number'),
              defaultSpacerSmall,
              _InputField(
                controller: _upiNumberController,
                hint: 'Enter 10-digit mobile number',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _validateUpiMobile,
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  _FieldLabel(text: 'UPI ID'),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: AppText(
                      text: 'Optional',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A6CF7),
                    ),
                  ),
                ],
              ),
              defaultSpacerSmall,
              _InputField(
                controller: _upiIdController,
                hint: 'e.g. name@upi',
                keyboardType: TextInputType.emailAddress,
                validator: _validateUpiId,
              ),

              SizedBox(height: 16.h),

              // UPI helper info
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppText(
                        text:
                            'Accepted UPI formats: name@upi, mobile@paytm, mobile@gpay, mobile@phonepe',
                        fontSize: 11.sp,
                        color: const Color(0xFF795548),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // ── Security Info Card ───────────────────────────────────
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFBFD4FF), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔒', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppText(
                      text:
                          'Your payment details are encrypted and stored securely. They will only be used for delivery payouts.',
                      fontSize: 12.sp,
                      color: AppColors.textDefaultSecondarycolor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

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

// ─── Field Label ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  Widget build(BuildContext context) {
    return AppText(
      text: text,
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textnaturalcolor,
    );
  }
}

// ─── Payment Mode Tab ──────────────────────────────────────────────────────────
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
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: AppText(
              text: label,
              fontSize: 14.sp,
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

// ─── Step Progress Bar ─────────────────────────────────────────────────────────
class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (int index = 0; index < totalSteps; index++) {
      final bool isActive = index < currentStep;
      final bool isCompleted = index < currentStep - 1;
      children.add(
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primarycolor : const Color(0xFFE0E0E0),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                : AppText(
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
      if (index < totalSteps - 1) {
        children.add(
          Expanded(
            child: Container(
              height: 2.h,
              color: isActive
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

// ─── Reusable Input Field ──────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textDefaultTertiarycolor,
          fontSize: 14.sp,
        ),
        suffixIcon: suffixIcon,
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
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
