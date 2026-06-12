import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/app/utils/spaces.dart';
import 'package:care_mall_rider/gen/assets.gen.dart';
import 'package:care_mall_rider/src/modules/auth/controller/auth_controller.dart';
import 'package:care_mall_rider/src/modules/auth/view/login_screen.dart';
import 'package:care_mall_rider/src/modules/auth/view/otp_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RegisterScreen extends GetView<AuthController> {
  RegisterScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  void _signup() {
    if (_formKey.currentState!.validate()) {
      controller.sendSignupOtp(
        phone: _phoneCtrl.text,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        onSuccess: () {
          Get.to(
            () => OTPVerificationScreen(
              phoneNumber: _phoneCtrl.text,
              mode: 'signup',
              name: _nameCtrl.text,
              email: _emailCtrl.text,
            ),
          );
        },
      );
    }
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: defaultPaddingLarge,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and Description
                SizedBox(
                  width: 170,
                  height: 40,
                  child: Assets.icons.appLogoPng.image(fit: BoxFit.fitHeight),
                ),
                defaultSpacerLarge,

                // Title & Subtitle
                Text(
                  'Create an Account',
                  style: theme.textTheme.headlineMedium,
                ),
                defaultSpacerTiny,
                Text(
                  'Welcome! please enter your details.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                defaultSpacerLarge,

                // Full Name
                AppText(
                  text: "Full Name",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                defaultSpacerSmall,
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter Name here',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Assets.icons.user.svg(),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                        color: AppColors
                            .primarycolor, // change to your theme color
                        width: 2,
                      ),
                    ),

                    // 👇 When Error
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                defaultSpacer,

                // Email
                AppText(
                  text: "Email",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                defaultSpacerSmall,
                TextFormField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter Email here',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Assets.icons.mail.svg(),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                        color: AppColors
                            .primarycolor, // change to your theme color
                        width: 2,
                      ),
                    ),

                    // 👇 When Error
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                defaultSpacer,

                // Phone Number
                AppText(
                  text: "Phone Number",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                defaultSpacerSmall,
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Enter Phone Number here',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Assets.icons.phone.svg(),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                defaultSpacer,

                // Password
                defaultSpacer24,

                // Sign Up Button
                Obx(
                  () => AppButton(
                    isLoading: controller.isLoading.value,
                    child: AppText(
                      text: "Sign Up",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whitecolor,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _signup();
                    },
                  ),
                ),
                defaultSpacer,

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Get.to(() => LoginScreen()),
                      child: Text(
                        'Login',
                        style: theme.textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }
}
