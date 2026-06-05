import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/home_screen.dart';
import 'package:care_mall_rider/src/modules/profile/controller/profile_repo.dart';
import 'package:care_mall_rider/src/modules/profile/model/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

class WithdrawalSuccessScreen extends StatefulWidget {
  final num amount;
  const WithdrawalSuccessScreen({super.key, required this.amount});

  State<WithdrawalSuccessScreen> createState() =>
      _WithdrawalSuccessScreenState();
}

class _WithdrawalSuccessScreenState extends State<WithdrawalSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _cardController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _burstAnimation;

  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  Future<RiderProfile>? _profileFuture;
  final AudioPlayer _audioPlayer = AudioPlayer();

  void initState() {
    super.initState();
    _profileFuture = ProfileRepo.getProfile().then((json) {
      final data = json['deliveryBoy'] ?? json['rider'] ?? json['data'] ?? json;
      return RiderProfile.fromJson(data as Map<String, dynamic>);
    });

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Circle pops in
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Checkmark draws
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOutCubic),
      ),
    );

    // Burst ring expands and fades
    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    // Card slides up and fades in
    _cardSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _playAnimations();
  }

  Future<void> _playAnimations() async {
    // Play sound immediately
    try {
      await _audioPlayer.play(AssetSource('sound/sound.mp3'));
    } catch (e) {
      // Ignore if sound fails
    }

    await _iconController.forward();
    await _cardController.forward();
  }

  void dispose() {
    _iconController.dispose();
    _cardController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121418), // Deep rich dark background
      body: FutureBuilder<RiderProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
              ),
            );
          }

          final profile = snapshot.data;
          final bool isBank = profile?.paymentMode == 'bank';
          final p = profile;

          final String destTitle = (isBank && p != null)
              ? p.bankName
              : 'UPI Transfer';
          final String destSubtitle = (isBank && p != null)
              ? '•••• ${p.accountNumber.length > 4 ? p.accountNumber.substring(p.accountNumber.length - 4) : p.accountNumber}'
              : profile?.upiId ?? profile?.upiNumber ?? '';

          return Stack(
            children: [
              // Background mesh/gradient effect
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.4),
                      radius: 1.2,
                      colors: [
                        Color(0xFF1A3325), // Dark green glow
                        Color(0xFF121418),
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            SizedBox(height: 60.h),
                            // Icon Section
                            Center(
                              child: SizedBox(
                                width: 140.w,
                                height: 140.w,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Burst effect
                                    AnimatedBuilder(
                                      animation: _burstAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale:
                                              1.0 +
                                              (_burstAnimation.value * 0.8),
                                          child: Opacity(
                                            opacity:
                                                1.0 - _burstAnimation.value,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF00E676,
                                                  ),
                                                  width: 4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // Main Icon
                                    ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: Container(
                                        width: 90.w,
                                        height: 90.w,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF00E676,
                                              ).withValues(alpha: 0.4),
                                              blurRadius: 30,
                                              spreadRadius: 10,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: AnimatedBuilder(
                                            animation: _checkAnimation,
                                            builder: (context, child) {
                                              return CustomPaint(
                                                size: Size(35.w, 35.w),
                                                painter: _PremiumCheckPainter(
                                                  _checkAnimation.value,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            // Title
                            AppText(
                              text: 'Withdrawal Requested',
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterspace: -0.5,
                            ),
                            SizedBox(height: 8.h),
                            AppText(
                              text: 'Your request is being processed',
                              fontSize: 15.sp,
                              color: Colors.white54,
                              fontWeight: FontWeight.w400,
                            ),

                            SizedBox(height: 48.h),

                            // Receipt Card
                            SlideTransition(
                              position: _cardSlideAnimation,
                              child: FadeTransition(
                                opacity: _cardFadeAnimation,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 40,
                                          spreadRadius: -10,
                                          offset: const Offset(0, 20),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 32.h,
                                            bottom: 24.h,
                                          ),
                                          child: Column(
                                            children: [
                                              AppText(
                                                text: 'WITHDRAWAL AMOUNT',
                                                fontSize: 11.sp,
                                                color: Colors.grey[500]!,
                                                fontWeight: FontWeight.w800,
                                                letterspace: 1.5,
                                              ),
                                              SizedBox(height: 8.h),
                                              AppText(
                                                text:
                                                    '₹${widget.amount.toStringAsFixed(2)}',
                                                fontSize: 42.sp,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF121418),
                                                letterspace: -2.0,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Dashed Divider
                                        const _DashedDivider(),

                                        Padding(
                                          padding: EdgeInsets.all(24.w),
                                          child: Column(
                                            children: [
                                              _buildPremiumDetailRow(
                                                'To',
                                                destTitle,
                                                destSubtitle,
                                              ),
                                              SizedBox(height: 24.h),
                                              _buildPremiumDetailRow(
                                                'Date',
                                                DateFormat(
                                                  'MMM dd, yyyy',
                                                ).format(DateTime.now()),
                                                DateFormat(
                                                  'hh:mm a',
                                                ).format(DateTime.now()),
                                              ),
                                              SizedBox(height: 24.h),
                                              _buildPremiumDetailRow(
                                                'Transaction ID',
                                                'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                                                'Completed',
                                                valueColor: const Color(
                                                  0xFF00E676,
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
                          ],
                        ),
                      ),
                    ),

                    // Done Button
                    FadeTransition(
                      opacity: _cardFadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Get.offAll(() => const HomeScreen()),
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              width: double.infinity,
                              height: 60.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Center(
                                child: AppText(
                                  text: 'Back to Home',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumDetailRow(
    String label,
    String value,
    String subtitle, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          text: label,
          fontSize: 14.sp,
          color: Colors.grey[500]!,
          fontWeight: FontWeight.w500,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppText(
              text: value,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF121418),
            ),
            SizedBox(height: 2.h),
            AppText(
              text: subtitle,
              fontSize: 13.sp,
              color: Colors.grey[500]!,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.h,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashWidth = 6.0;
    final dashSpace = 4.0;
    double startX = 24.0;

    while (startX < size.width - 24.0) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PremiumCheckPainter extends CustomPainter {
  final double progress;
  _PremiumCheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.75);
    path.lineTo(size.width * 0.85, size.height * 0.25);

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(
      0,
      pathMetrics.length * progress,
    );

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
