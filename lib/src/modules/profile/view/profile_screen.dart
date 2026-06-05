import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/app/utils/kyc_storage.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/src/modules/auth/view/login_screen.dart';
import 'package:care_mall_rider/src/modules/profile/controller/profile_repo.dart';
import 'package:care_mall_rider/src/modules/profile/model/profile_model.dart';
import 'package:care_mall_rider/src/modules/profile/view/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<RiderProfile>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profileFuture = ProfileRepo.getProfile().then((json) async {
        final data =
            json['deliveryBoy'] ?? json['rider'] ?? json['data'] ?? json;
        var profile = RiderProfile.fromJson(data as Map<String, dynamic>);

        // Update local storage for fields that are present
        StorageService.saveUserName(profile.name);
        StorageService.saveUserAvatar(profile.avatar);

        if (profile.address.isNotEmpty) {
          StorageService.saveUserAddress(profile.address);
        } else {
          // If server doesn't return an address, try to restore from local storage
          final localAddress = await StorageService.getUserAddress();
          if (localAddress != null && localAddress.isNotEmpty) {
            profile = RiderProfile(
              id: profile.id,
              name: profile.name,
              phone: profile.phone,
              email: profile.email,
              address: localAddress,
              avatar: profile.avatar,
              status: profile.status,
              kycStatus: profile.kycStatus,
              vehicleType: profile.vehicleType,
              registrationNumber: profile.registrationNumber,
              paymentMode: profile.paymentMode,
              accountHolderName: profile.accountHolderName,
              accountNumber: profile.accountNumber,
              ifscCode: profile.ifscCode,
              bankName: profile.bankName,
              upiId: profile.upiId,
              upiNumber: profile.upiNumber,
            );
          }
        }

        return profile;
      });
    });
  }

  Future<void> _logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: AppText(
          text: 'Logout',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
        content: AppText(
          text: 'Are you sure you want to logout?',
          fontSize: 14.sp,
          color: AppColors.textDefaultSecondarycolor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const AppText(
              text: 'Cancel',
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const AppText(
              text: 'Logout',
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await StorageService.clearAuthData();
    await KycStorage.clearAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 255),
      body: FutureBuilder<RiderProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: () async => _loadProfile(),
              color: AppColors.primarycolor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12.h),
                        AppText(
                          text: 'Could not load profile',
                          fontSize: 14.sp,
                          color: Colors.grey[600]!,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final profile = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // ── Hero Header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(
                  profile: profile,
                  onEdit: () async {
                    final updated = await Get.to<bool>(
                      () => EditProfileScreen(profile: profile),
                    );
                    if (updated == true) _loadProfile();
                  },
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Personal Details card
                    _InfoCard(
                      title: 'Personal Details',
                      icon: SvgPicture.asset(
                        'assets/icons/user.svg',
                        colorFilter: const ColorFilter.mode(
                          AppColors.primarycolor,
                          BlendMode.srcIn,
                        ),
                        width: 18.w,
                      ),
                      rows: [
                        _RowData(
                          SvgPicture.asset(
                            'assets/icons/phone.svg',
                            width: 16.sp,
                            colorFilter: const ColorFilter.mode(
                              AppColors.primarycolor,
                              BlendMode.srcIn,
                            ),
                          ),
                          'Phone',
                          profile.phone,
                        ),
                        _RowData(
                          SvgPicture.asset(
                            'assets/icons/mail.svg',
                            width: 16.sp,
                            colorFilter: const ColorFilter.mode(
                              AppColors.primarycolor,
                              BlendMode.srcIn,
                            ),
                          ),
                          'Email',
                          profile.email.isEmpty ? '—' : profile.email,
                        ),
                        _RowData(
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.primarycolor,
                          ),
                          'Address',
                          profile.address.isEmpty ? '—' : profile.address,
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // KYC banner
                    _StatusBanner(kycStatus: profile.kycStatus),

                    SizedBox(height: 20.h),

                    // Vehicle & Payment mini cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MiniCard(
                            icon: Icon(
                              Icons.two_wheeler_rounded,
                              size: 15.sp,
                              color: AppColors.primarycolor,
                            ),
                            title: 'Vehicle',
                            lines: [
                              profile.vehicleType,
                              profile.registrationNumber.isEmpty
                                  ? '—'
                                  : profile.registrationNumber,
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _MiniCard(
                            icon: Icon(
                              Icons.payments_rounded,
                              size: 15.sp,
                              color: AppColors.primarycolor,
                            ),
                            title: 'Payment',
                            lines: profile.paymentMode == 'bank'
                                ? [
                                    profile.bankName.isEmpty
                                        ? 'BANK'
                                        : profile.bankName,
                                    profile.accountNumber.length > 4
                                        ? '**** ${profile.accountNumber.substring(profile.accountNumber.length - 4)}'
                                        : profile.accountNumber.isEmpty
                                        ? '—'
                                        : profile.accountNumber,
                                  ]
                                : [
                                    'UPI',
                                    profile.upiNumber.isEmpty
                                        ? '—'
                                        : profile.upiNumber,
                                  ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),

                    // Logout
                    _LogoutButton(onTap: _logout),
                    SizedBox(height: 20.h),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final RiderProfile profile;
  final VoidCallback onEdit;

  const _HeroHeader({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          // Edit button (Top Right)
          Positioned(
            top: 20.h,
            right: 20.w,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: AppColors.primarycolor,
                  size: 18.sp,
                ),
              ),
            ),
          ),

          // Centered Content
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.white,
                      backgroundImage: profile.avatar.isNotEmpty
                          ? NetworkImage(profile.avatar)
                          : null,
                      child: profile.avatar.isEmpty
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
                  SizedBox(height: 12.h),

                  // Name & info
                  AppText(
                    text: profile.name,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textnaturalcolor,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    text: profile.phone,
                    fontSize: 14.sp,
                    color: AppColors.textDefaultSecondarycolor,
                    fontWeight: FontWeight.w500,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Chip(
                        label: profile.status.toUpperCase(),
                        color: AppColors.primarycolor.withValues(alpha: 0.1),
                        textColor: AppColors.primarycolor,
                      ),
                      SizedBox(width: 8.w),
                      _Chip(
                        label: '⭐  Gold Rider',
                        color: Colors.amber.withValues(alpha: 0.1),
                        textColor: Colors.amber[800]!,
                      ),
                    ],
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

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const _Chip({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: AppText(
        text: label,
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        color: textColor ?? Colors.white,
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _RowData {
  final Widget icon;
  final String label;
  final String value;
  _RowData(this.icon, this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final List<_RowData> rows;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
            child: Row(
              children: [
                icon,
                SizedBox(width: 8.w),
                AppText(
                  text: title,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textnaturalcolor,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final row = e.value;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primarycolor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: SizedBox(
                          width: 16.sp,
                          height: 16.sp,
                          child: row.icon,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: row.label,
                              fontSize: 11.sp,
                              color: Colors.grey[500]!,
                              fontWeight: FontWeight.w500,
                            ),
                            SizedBox(height: 2.h),
                            AppText(
                              text: row.value,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textnaturalcolor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(height: 1, color: Colors.grey[100], indent: 52.w),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Mini Card ────────────────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final List<String> lines;

  const _MiniCard({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: AppColors.primarycolor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: icon,
              ),
              SizedBox(width: 8.w),
              AppText(
                text: title,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textnaturalcolor,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...lines.map(
            (l) => Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: AppText(
                text: l,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDefaultSecondarycolor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KYC Status Banner ────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String kycStatus;

  const _StatusBanner({required this.kycStatus});

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon, label) = switch (kycStatus.toLowerCase()) {
      'approved' => (
        Colors.green[700]!,
        const Color(0xFFEBFFEE),
        Icons.verified_rounded,
        'KYC Approved',
      ),
      'rejected' => (
        Colors.red[600]!,
        const Color(0xFFFFEDED),
        Icons.cancel_rounded,
        'KYC Rejected',
      ),
      'under_review' => (
        Colors.orange[700]!,
        const Color(0xFFFFF4E5),
        Icons.hourglass_top_rounded,
        'Under Review',
      ),
      _ => (
        Colors.grey[600]!,
        const Color(0xFFF0F0F0),
        Icons.info_outline_rounded,
        'KYC Pending',
      ),
    };

    final subtitle = switch (kycStatus.toLowerCase()) {
      'approved' =>
        'Your identity has been verified. You can now accept deliveries.',
      'rejected' =>
        'Your documents were not accepted. Please re-submit with valid documents.',
      'under_review' =>
        'Your documents are being reviewed. This usually takes 1–2 business days.',
      _ => 'Complete your KYC to start accepting deliveries.',
    };

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 14.sp, color: color),
              SizedBox(width: 6.w),
              AppText(
                text: 'Documents & KYC',
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: label,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      text: subtitle,
                      fontSize: 11.sp,
                      color: color.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5),
                size: 20.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/userred.svg',
              width: 18.sp,
              colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
            ),
            SizedBox(width: 8.w),
            AppText(
              text: 'Log out',
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.red[600]!,
            ),
          ],
        ),
      ),
    );
  }
}
