import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/home_screen.dart';
import 'package:care_mall_rider/src/modules/kyc/controller/kyc_controller.dart';
import 'package:care_mall_rider/src/modules/kyc/view/driving_license_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  late final KYCController _kycController;

  void initState() {
    super.initState();
    _kycController = Get.find<KYCController>();
    _kycController.fetchKycStatus();
  }

  void _navigateHome() {
    Get.offAll(() => const HomeScreen());
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Obx(() {
        final bool isUnderReview = _kycController.isKycUnderReview;
        final bool isRejected = _kycController.isKycRejected;
        final bool isApproved = _kycController.isKycApproved;

        // Navigate to home if approved
        if (isApproved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateHome();
          });
        }

        if (_kycController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // ─── Header ───────────────────────────────────────────────
            _KycHeader(status: _kycController.kycStatus.value),

            // ─── Body ─────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUnderReview) _buildReviewBanner(),
                    if (isRejected) _buildRejectedBanner(),

                    const SizedBox(height: 8),
                    AppText(
                      text: "WHAT YOU'LL NEED",
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDefaultSecondarycolor,
                      letterspace: 0.8,
                    ),
                    const SizedBox(height: 12),

                    // KYC Step Cards
                    _KycStepCard(
                      icon: Icons.badge_outlined,
                      iconBgColor: const Color(0xFFE8F0FE),
                      iconColor: const Color(0xFF4A6CF7),
                      title: 'Driving License',
                      subtitle: 'Upload front & back of your license',
                    ),
                    const SizedBox(height: 10),

                    _KycStepCard(
                      icon: Icons.account_balance_outlined,
                      iconBgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      title: 'Bank / UPI Details',
                      subtitle: 'Add your payout bank or UPI account',
                    ),
                    const SizedBox(height: 10),

                    _KycStepCard(
                      icon: Icons.directions_car_outlined,
                      iconBgColor: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFFFA621),
                      title: 'Vehicle Selection',
                      subtitle: 'Choose the vehicle type for deliveries',
                    ),

                    const SizedBox(height: 32),

                    // ─── Start KYC Button ──────────────────────────────
                    if (!isUnderReview)
                      AppButton(
                        borderRadius: 30,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DrivingLicenseScreen(),
                            ),
                          );
                        },
                        child: AppText(
                          text: isRejected
                              ? 'Re-submit KYC Verification'
                              : 'Start KYC Verification',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.whitecolor,
                        ),
                      ),
                    if (isUnderReview)
                      Center(
                        child: AppText(
                          text: 'Submission under process',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDefaultSecondarycolor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildReviewBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1976D2)),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              text:
                  'Your KYC is currently under review. This usually takes 24-48 hours.',
              fontSize: 13,
              color: const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              text:
                  'Your KYC was rejected. Please review your details and re-submit.',
              fontSize: 13,
              color: const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Red Header Widget ─────────────────────────────────────────────────────────
class _KycHeader extends StatelessWidget {
  final String status;

  const _KycHeader({required this.status});

  Widget build(BuildContext context) {
    String headerTitle = 'KYC Verification';
    String headerSubtitle = 'Complete your KYC to start delivering and earning';
    IconData headerIcon = Icons.verified_user_outlined;
    Color headerColor = AppColors.primarycolor;

    if (status.toLowerCase() == 'under_review') {
      headerTitle = 'Verification Under Review';
      headerSubtitle = 'We are currently reviewing your documents';
      headerIcon = Icons.query_builder_rounded;
      headerColor = const Color(0xFF1976D2);
    } else if (status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'verified') {
      headerTitle = 'Verification Approved';
      headerSubtitle = 'Your KYC has been successfully verified';
      headerIcon = Icons.verified_rounded;
      headerColor = Colors.green;
    } else if (status.toLowerCase() == 'rejected') {
      headerTitle = 'Action Required';
      headerSubtitle = 'Your KYC was not approved';
      headerIcon = Icons.warning_amber_rounded;
      headerColor = const Color(0xFFD32F2F);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            children: [
              // Shield icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(headerIcon, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 16),

              AppText(
                text: headerTitle,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.whitecolor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              AppText(
                text: headerSubtitle,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── KYC Step Card ─────────────────────────────────────────────────────────────
class _KycStepCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _KycStepCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: title,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textnaturalcolor,
                  ),
                  const SizedBox(height: 3),
                  AppText(
                    text: subtitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textDefaultSecondarycolor,
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
