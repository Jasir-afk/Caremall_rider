import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/app/utils/spaces.dart';
import 'package:care_mall_rider/gen/assets.gen.dart';
import 'package:care_mall_rider/src/modules/auth/controller/auth_controller.dart';
import 'package:care_mall_rider/src/modules/auth/view/otp_verification_screen.dart';
import 'package:care_mall_rider/src/modules/auth/view/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class LoginScreen extends GetView<AuthController> {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  void _login() {
    if (_formKey.currentState!.validate()) {
      controller.sendLoginOtp(
        phone: _phoneController.text,
        onSuccess: () {
          Get.to(
            () => OTPVerificationScreen(
              phoneNumber: _phoneController.text,
              mode: 'login',
            ),
          );
        },
        onAccountDeleted: (message) {
          // Redirect to registration/signup flow
          Get.to(() => RegisterScreen());
        },
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo and Description
                        SizedBox(
                          width: 170,
                          height: 40,
                          child: Assets.icons.appLogoPng.image(
                            fit: BoxFit.fitHeight,
                          ),
                        ),

                        defaultSpacerLarge,
                        // SizedBox(height: 100.h),
                        AppText(
                          text: 'Login',
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textnaturalcolor,
                        ),
                        AppText(
                          text: 'Sign in using your mobile number ',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textDefaultSecondarycolor,
                        ), // defaultSpacerLarge,
                        defaultSpacerLarge,
                        // defaultSpacerSmall,
                        AppText(
                          text: "Mobile Number",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        defaultSpacerSmall,

                        // Mobile number field with validator
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Enter Mobile Number here',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Assets.icons.phone.svg(),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            // 👇 Default Border
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            // 👇 When Enabled
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),

                            // 👇 When Focused
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(
                                color: AppColors.primarycolor,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                              return 'Please enter a valid 10-digit number';
                            }
                            return null;
                          },
                        ),

                        defaultSpacer,
                        Obx(
                          () => AppButton(
                            isLoading: controller.isLoading.value,
                            child: AppText(
                              text: "Send OTP",
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.whitecolor,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _login();
                            },
                          ),
                        ),
                        defaultSpacer,

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?"),
                            TextButton(
                              onPressed: () => Get.to(() => RegisterScreen()),
                              child: Text(
                                'SignUp',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
