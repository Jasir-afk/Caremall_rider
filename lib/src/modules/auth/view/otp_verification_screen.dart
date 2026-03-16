import 'dart:async';
import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/app/utils/network/auth_service.dart';
import 'package:care_mall_rider/app/utils/spaces.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/gen/assets.gen.dart';
import 'package:care_mall_rider/src/modules/kyc/view/kyc_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:care_mall_rider/src/modules/home_screen/view/home_screen.dart';
import 'package:care_mall_rider/src/modules/kyc/controller/kyc_repo.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String mode; // "login" or "signup"
  final String? name;
  final String? email;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.mode,
    this.name,
    this.email,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  Timer? _timer;
  int _start = 30;
  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    // Collect entered OTP (ignore empty boxes — join only filled ones)
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length != 6) {
      AppSnackbar.showError(
        title: 'Invalid OTP',
        message: 'Please enter the complete 6-digit OTP',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.verifyOtp(
        phone: widget.phoneNumber,
        otp: otp,
      );
      // ── Always save login state first (before any context use) ────────
      final bool isSuccess = result['success'] == true;
      if (isSuccess) {
        final token = result['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          await StorageService.saveAuthToken(token);
        }
        // Save user profile data
        final responseData = result['data'] ?? {};
        final userData = responseData['deliveryBoy'] ?? {};
        if (userData.isNotEmpty) {
          if (userData['name'] != null) {
            await StorageService.saveUserName(userData['name'].toString());
          }
          if (userData['email'] != null) {
            await StorageService.saveUserEmail(userData['email'].toString());
          }
          if (userData['phone'] != null) {
            await StorageService.savePhoneNumber(userData['phone'].toString());
          }
          if (userData['kyc'] != null && userData['kyc']['status'] != null) {
            await StorageService.saveKycStatus(
              userData['kyc']['status'].toString(),
            );
          } else if (userData['status'] != null) {
            await StorageService.saveKycStatus(userData['status'].toString());
          }
        }
      }
      // ──────────────────────────────────────────────────────────────────
      if (!mounted) return;
      if (isSuccess) {
        if (mounted) {
          AppSnackbar.showSuccess(
            title: 'Verified',
            message: result['message'] ?? 'OTP verified successfully!',
          );
        }
        if (isSuccess) {
          // Check KYC status before navigating
          await KycRepo.getKycStatus();
          final bool isKycDone = await StorageService.isKycCompleted();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => isKycDone
                    ? const HomeScreen()
                    : const KycVerificationScreen(),
              ),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          AppSnackbar.showError(
            title: 'Verification Failed',
            message: result['message'] ?? 'Invalid OTP. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(title: 'Error', message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });
    try {
      final result = await AuthService.sendOtp(
        phone: widget.phoneNumber,
        mode: widget.mode,
        name: widget.name ?? '',
        email: widget.email ?? '',
      );

      if (mounted) {
        if (result['success']) {
          AppSnackbar.showSuccess(title: 'Resent', message: result['message']);
        } else {
          AppSnackbar.showError(
            title: 'Resend Failed',
            message: result['message'],
          );
        }
        if (result['success']) {
          setState(() {
            _start = 30;
          });
          startTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(title: 'Error', message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _editNumber() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    kToolbarHeight -
                    (defaultPadding * 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CareMall Logo
                  SizedBox(
                    width: 150.w,
                    height: 35.h,
                    child: Assets.icons.appLogoPng.image(fit: BoxFit.fitHeight),
                  ),
                  defaultSpacerLarge,

                  // Title
                  AppText(
                    text: 'Enter OTP',
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textnaturalcolor,
                  ),
                  defaultSpacerSmall,

                  // Subtitle with phone number
                  AppText(
                    text: 'A 6-digit code was sent to ${widget.phoneNumber}',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textDefaultSecondarycolor,
                  ),
                  defaultSpacerLarge,

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 50.w,
                        height: 60.h,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(
                                color: AppColors.primarycolor,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                              6,
                            ), // Allow up to 6 digits for paste
                          ],
                          onChanged: (value) {
                            // Handle paste - if multiple digits are pasted
                            if (value.length > 1) {
                              // Clear current field first
                              _otpControllers[index].text = '';

                              // Distribute the pasted digits across all fields starting from current index
                              final digits = value.split('');
                              for (
                                int i = 0;
                                i < digits.length && (index + i) < 6;
                                i++
                              ) {
                                _otpControllers[index + i].text = digits[i];
                              }

                              Future.microtask(() {
                                FocusManager.instance.primaryFocus?.unfocus();
                              });

                              return;
                            }

                            // Handle single character input
                            if (value.length == 1) {
                              if (index < 5) {
                                // Move to next field (delay to avoid crash on key event)
                                Future.microtask(() {
                                  if (mounted) {
                                    _otpFocusNodes[index + 1].requestFocus();
                                  }
                                });
                              }
                            } else if (value.isEmpty && index > 0) {
                              // Move to previous field on backspace (delay to avoid crash)
                              Future.microtask(() {
                                if (mounted) {
                                  _otpFocusNodes[index - 1].requestFocus();
                                }
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  defaultSpacerLarge,
                  // Resend OTP
                  Center(
                    child: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _start > 0
                        ? AppText(
                            text: 'Resend OTP in $_start s',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          )
                        : TextButton(
                            onPressed: _resendOTP,
                            child: AppText(
                              text: 'Resend OTP',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                  ),
                  defaultSpacer,

                  // Verify Button
                  AppButton(
                    isLoading: _isLoading,
                    child: AppText(
                      text: "Verify OTP",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whitecolor,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _verifyOTP();
                    },
                  ),
                  defaultSpacer,

                  // Edit Number
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          text: 'Wrong number? ',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textDefaultSecondarycolor,
                        ),
                        TextButton(
                          onPressed: _editNumber,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: AppText(
                            text: 'Edit number',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
