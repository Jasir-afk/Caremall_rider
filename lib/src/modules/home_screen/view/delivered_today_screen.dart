import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class DeliveredTodayScreen extends StatefulWidget {
  const DeliveredTodayScreen({super.key});

  State<DeliveredTodayScreen> createState() => _DeliveredTodayScreenState();
}

class _DeliveredTodayScreenState extends State<DeliveredTodayScreen> {
  late Future<DashboardModel> _future;

  void initState() {
    super.initState();
    _future = OrderRepo.getDeliveredTodayData();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = OrderRepo.getDeliveredTodayData();
    });
    await _future;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textnaturalcolor,
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: 'Delivered Today',
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textnaturalcolor,
        ),
      ),
      body: FutureBuilder<DashboardModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: AppColors.primarycolor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 56.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          AppText(
                            text: 'Failed to load data',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textnaturalcolor,
                          ),
                          SizedBox(height: 8.h),
                          AppText(
                            text: 'Check your connection and try again.',
                            fontSize: 13.sp,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: AppColors.primarycolor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Summary Card ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                    child: _SummaryCard(summary: data.summary),
                  ),
                ),

                // ── Section Header ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: "Today's Orders",
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textnaturalcolor,
                        ),
                        AppText(
                          text: '${data.todayOrders.length} orders',
                          fontSize: 13.sp,
                          color: Colors.grey[500]!,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Empty State ───────────────────────────────────────
                if (data.todayOrders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 56.sp,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 12.h),
                          AppText(
                            text: 'No orders today',
                            fontSize: 15.sp,
                            color: Colors.grey[500]!,
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Orders List ───────────────────────────────────────
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _OrderCard(
                          order: data.todayOrders[index],
                          index: index,
                        ),
                      );
                    }, childCount: data.todayOrders.length),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final DashboardSummary summary;
  const _SummaryCard({required this.summary});

  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFEF6C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: "Today's Summary",
            fontSize: 12.sp,
            color: Colors.white70,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Deliveries',
                  value: '${summary.todayDeliveries}',
                  icon: Icons.local_shipping_rounded,
                ),
              ),
              // Expanded(
              //   child: _StatItem(
              //     label: 'COD Collected',
              //     value: '₹${summary.todayCodCollected.toStringAsFixed(0)}',
              //     icon: Icons.account_balance_wallet_rounded,
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 10.h),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _StatItem(
          //         label: 'Pending',
          //         value: '${summary.pendingOrders}',
          //         icon: Icons.pending_actions_rounded,
          //       ),
          //     ),
          //     Expanded(
          //       child: _StatItem(
          //         label: 'Total Earned',
          //         value: '₹${summary.totalEarned.toStringAsFixed(0)}',
          //         icon: Icons.trending_up_rounded,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: Colors.white, size: 16.sp),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: value,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            AppText(text: label, fontSize: 11.sp, color: Colors.white70),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Order Card
// ─────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final TodayOrder order;
  final int index;

  const _OrderCard({required this.order, required this.index});

  Color get _statusColor {
    switch (order.orderStatus.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'item_received':
        return const Color(0xFF1E7E4C);
      case 'cancelled':
      case 'failed':
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'shipped':
      case 'out_for_delivery':
      case 'item_picked':
      case 'approved':
        return const Color(0xFF1A56DB);
      case 'pending':
      case 'requested':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF374151);
    }
  }

  Color get _statusBgColor {
    switch (order.orderStatus.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'item_received':
        return const Color(0xFFE6F4EE);
      case 'cancelled':
      case 'failed':
      case 'rejected':
        return const Color(0xFFFFE3E3);
      case 'shipped':
      case 'out_for_delivery':
      case 'item_picked':
      case 'approved':
        return const Color(0xFFE8F0FE);
      case 'pending':
      case 'requested':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String get _statusLabel =>
      order.orderStatus.replaceAll('_', ' ').toUpperCase();

  Widget build(BuildContext context) {
    final timeStr = order.deliveredAt != null
        ? DateFormat('hh:mm a').format(order.deliveredAt!.toLocal())
        : '';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: order.orderId,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textnaturalcolor,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _statusBgColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: AppText(
                  text: _statusLabel,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),
          Divider(height: 1, color: Colors.grey[100]),
          SizedBox(height: 10.h),

          // ── Customer ──
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14.sp,
                color: Colors.grey[500],
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: AppText(
                  text: order.shippingAddress.fullName,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textnaturalcolor,
                ),
              ),
              if (timeStr.isNotEmpty)
                AppText(
                  text: timeStr,
                  fontSize: 11.sp,
                  color: Colors.grey[400]!,
                ),
            ],
          ),

          SizedBox(height: 4.h),

          // ── Address ──
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14.sp,
                color: Colors.grey[500],
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: AppText(
                  text:
                      '${order.shippingAddress.addressLine1}, ${order.shippingAddress.city}',
                  fontSize: 12.sp,
                  color: Colors.grey[600]!,
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // ── Bottom Row: Payment + Amount ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Payment badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: order.isCod
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.isCod ? Icons.money_rounded : Icons.payment_rounded,
                      size: 12.sp,
                      color: order.isCod
                          ? const Color(0xFFE65100)
                          : Colors.green[700],
                    ),
                    SizedBox(width: 4.w),
                    AppText(
                      text: order.paymentMethod.toUpperCase(),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: order.isCod
                          ? const Color(0xFFE65100)
                          : Colors.green[700]!,
                    ),
                  ],
                ),
              ),

              AppText(
                text: '₹ ${order.amountToCollect.toStringAsFixed(0)}',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textnaturalcolor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
