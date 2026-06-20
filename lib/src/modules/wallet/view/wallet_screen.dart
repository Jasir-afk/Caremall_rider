import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/src/modules/wallet/controller/wallet_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedTab = 0; // 0: Transactions, 1: Withdrawals

  Widget build(BuildContext context) {
    final controller = Get.put(WalletController());

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value &&
              controller.walletData.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error state with retry
          if (controller.errorMessage.value != null &&
              controller.walletData.value == null) {
            return RefreshIndicator(
              onRefresh: controller.refreshAll,
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
                            text: 'Failed to Load Wallet',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textnaturalcolor,
                          ),
                          SizedBox(height: 8.h),
                          AppText(
                            text: controller.errorMessage.value!,
                            fontSize: 13.sp,
                            color: Colors.grey,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final wallet = controller.walletData.value;
          final transactions = wallet?.transactions ?? [];

          return RefreshIndicator(
            onRefresh: controller.refreshAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ──────────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: AppText(
                    text: 'My Wallet',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textnaturalcolor,
                  ),
                ),

                // ─── Balance Card ────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primarycolor,
                          AppColors.primarycolor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primarycolor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: 'Available Balance',
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        SizedBox(height: 8.h),
                        AppText(
                          text:
                              '₹ ${wallet?.balance?.toStringAsFixed(2) ?? '0.00'}',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: 'Total Earned',
                                  fontSize: 12.sp,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                AppText(
                                  text:
                                      '₹ ${wallet?.totalEarned?.toStringAsFixed(2) ?? '0.00'}',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: 'Total Withdrawn',
                                  fontSize: 12.sp,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                AppText(
                                  text:
                                      '₹ ${wallet?.totalWithdrawn?.toStringAsFixed(2) ?? '0.00'}',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _showWithdrawDialog(context, controller);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primarycolor,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: AppText(
                                text: 'Withdraw',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primarycolor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // ─── Recent Transactions Title ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AppText(
                    text: 'Recent Transactions',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textnaturalcolor,
                  ),
                ),

                SizedBox(height: 12.h),

                // ─── Transaction / Withdrawal Requests Custom Tabs ──────────
                Container(
                  height: 45.h,
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      _buildTab('Transactions', 0),
                      _buildTab('Withdrawals', 1),
                    ],
                  ),
                ),

                Expanded(
                  child: _selectedTab == 0
                      ? // ─── Transaction List ──────────────────────────
                        (transactions.isEmpty
                            ? Center(
                                child: AppText(
                                  text: 'No transactions yet',
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                itemCount: transactions.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: 12.h),
                                itemBuilder: (context, index) {
                                  final tx = transactions[index];
                                  final isNegative = tx.type == 'debit';
                                  final dateStr = tx.createdAt != null
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(tx.createdAt!)
                                      : '';

                                  return _buildTransactionItem(
                                    title: tx.type == 'credit'
                                        ? 'Order Earning'
                                        : 'Withdrawal',
                                    subtitle: tx.description ?? '',
                                    amount:
                                        '${isNegative ? '-' : '+'} ₹ ${tx.amount?.toStringAsFixed(2) ?? '0.00'}',
                                    date: dateStr,
                                    isNegative: isNegative,
                                  );
                                },
                              ))
                      : // ─── Withdrawal Requests List ──────────────────
                        Obx(() {
                          final requests = controller.withdrawalRequests;
                          if (requests.isEmpty) {
                            return Center(
                              child: AppText(
                                text: 'No withdrawal requests',
                                fontSize: 14.sp,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            itemCount: requests.length,
                            separatorBuilder: (_, _) => SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              final req = requests[index];
                              final dateStr = req.createdAt != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(req.createdAt!)
                                  : '';

                              return _buildWithdrawalRequestItem(
                                amount: req.amount ?? 0,
                                status: req.status ?? 'pending',
                                date: dateStr,
                                paymentMode: req.paymentMode ?? 'upi',
                                adminNote: req.adminNote,
                                processedAt: req.processedAt,
                              );
                            },
                          );
                        }),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AppText(
              text: title,
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primarycolor : Colors.grey[600]!,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawalRequestItem({
    required num amount,
    required String status,
    required String date,
    required String paymentMode,
    String? adminNote,
    DateTime? processedAt,
  }) {
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'processed':
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'accepted':
        statusColor = const Color(0xFF2196F3); // blue
        statusIcon = Icons.thumb_up_alt_outlined;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case 'failed':
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline_rounded;
    }

    final processedDateStr = processedAt != null
        ? DateFormat('dd MMM yyyy').format(processedAt)
        : null;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: icon + amount + mode
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, size: 18.sp, color: statusColor),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: '₹ ${amount.toStringAsFixed(2)}',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textnaturalcolor,
                      ),
                      SizedBox(height: 2.h),
                      AppText(
                        text: 'Mode: ${paymentMode.toUpperCase()}',
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
              // Right: status badge + date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: AppText(
                      text: status.toUpperCase(),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    text: processedDateStr ?? date,
                    fontSize: 11.sp,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
          // Admin note (shown when accepted/processed)
          if (adminNote != null && adminNote.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14.sp,
                    color: statusColor,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: AppText(
                      text: adminNote,
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required String date,
    required bool isNegative,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isNegative ? Colors.red[50] : Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNegative
                  ? Icons.account_balance_wallet_outlined
                  : Icons.show_chart,
              size: 20.sp,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: title,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textnaturalcolor,
                ),
                SizedBox(height: 2.h),
                AppText(
                  text: subtitle,
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                text: amount,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isNegative ? Colors.red : Colors.green.shade700,
              ),
              AppText(text: date, fontSize: 11.sp, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WalletController controller) {
    final wallet = controller.walletData.value;
    final balance = (wallet?.balance ?? 0.0).toDouble();

    Get.bottomSheet(
      _WithdrawBottomSheet(
        controller: controller,
        balance: balance,
      ),
      isScrollControlled: true,
    );
  }
}

class _WithdrawBottomSheet extends StatefulWidget {
  final WalletController controller;
  final double balance;

  const _WithdrawBottomSheet({
    required this.controller,
    required this.balance,
  });


  State<_WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<_WithdrawBottomSheet> {
  late final TextEditingController amountController;
  bool isSlideEnabled = false;

  void initState() {
    super.initState();
    amountController = TextEditingController();
    amountController.addListener(_updateSlideState);
  }


  void dispose() {
    amountController.removeListener(_updateSlideState);
    amountController.dispose();
    super.dispose();
  }

  void _updateSlideState() {
    final amountStr = amountController.text.trim();
    if (amountStr.isEmpty) {
      if (isSlideEnabled) {
        setState(() {
          isSlideEnabled = false;
        });
      }
      return;
    }
    final amount = double.tryParse(amountStr);
    final enabled = amount != null && amount > 0;
    if (isSlideEnabled != enabled) {
      setState(() {
        isSlideEnabled = enabled;
      });
    }
  }


  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          AppText(
            text: 'Withdraw Funds',
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textnaturalcolor,
          ),
          SizedBox(height: 8.h),
          AppText(
            text: 'Enter the amount you want to withdraw from your wallet.',
            fontSize: 14.sp,
            color: Colors.grey.shade600,
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primarycolor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primarycolor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: 'Available Balance',
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    AppText(
                      text: '₹ ${widget.balance.toStringAsFixed(2)}',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primarycolor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textnaturalcolor,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textnaturalcolor,
              ),
              suffixIcon: TextButton(
                onPressed: () {
                  amountController.text = widget.balance.toStringAsFixed(2);
                },
                child: AppText(
                  text: 'MAX',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primarycolor,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.primarycolor),
              ),
            ),
          ),
          SizedBox(height: 32.h),
          SlideToWithdraw(
            text: 'Slide to Withdraw',
            enabled: isSlideEnabled,
            onSlideSuccess: () {
              final amountStr = amountController.text.trim();
              if (amountStr.isNotEmpty) {
                final amount = double.tryParse(amountStr);
                if (amount != null && amount > 0) {
                  if (amount <= widget.balance) {
                    Get.back();
                    widget.controller.requestWithdrawal(amount);
                  } else {
                    AppSnackbar.showError(
                      title: 'Insufficient Balance',
                      message:
                          'You cannot withdraw more than your available balance.',
                    );
                  }
                } else {
                  AppSnackbar.showError(
                    title: 'Invalid Amount',
                    message: 'Please enter a valid amount to withdraw.',
                  );
                }
              } else {
                AppSnackbar.showError(
                  title: 'Amount Required',
                  message: 'Please enter an amount to withdraw.',
                );
              }
            },
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

class SlideToWithdraw extends StatefulWidget {
  final VoidCallback onSlideSuccess;
  final String text;
  final bool enabled;

  const SlideToWithdraw({
    super.key,
    required this.onSlideSuccess,
    this.text = 'Slide to Withdraw',
    this.enabled = true,
  });


  State<SlideToWithdraw> createState() => _SlideToWithdrawState();
}

class _SlideToWithdrawState extends State<SlideToWithdraw> {
  double _dragPosition = 0;
  bool _isFinished = false;

  void didUpdateWidget(covariant SlideToWithdraw oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      setState(() {
        _dragPosition = 0;
      });
    }
  }

  Widget build(BuildContext context) {
    const double buttonHeight = 58.0;
    const double thumbSize = 46.0;
    const double padding = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDragDistance =
            constraints.maxWidth - thumbSize - (padding * 2);

        return Container(
          width: constraints.maxWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.primarycolor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Stack(
            children: [
              // Center text
              Center(
                child: Opacity(
                  opacity: widget.enabled
                      ? (1 - (_dragPosition / maxDragDistance)).clamp(0.2, 1.0)
                      : 0.6,
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: widget.enabled ? AppColors.whitecolor : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              // Drag handle
              Positioned(
                left: padding + _dragPosition,
                top: padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.enabled
                      ? (details) {
                          if (_isFinished) return;
                          setState(() {
                            _dragPosition = (_dragPosition + details.delta.dx)
                                .clamp(0.0, maxDragDistance);
                          });
                        }
                      : null,
                  onHorizontalDragEnd: widget.enabled
                      ? (details) async {
                          if (_isFinished) return;
                          if (_dragPosition >= maxDragDistance * 0.9) {
                            // Successful slide!
                            setState(() {
                              _dragPosition = maxDragDistance;
                              _isFinished = true;
                            });
                            widget.onSlideSuccess();
                            // Reset slide button after a short delay
                            Future.delayed(const Duration(milliseconds: 600), () {
                              if (mounted) {
                                setState(() {
                                  _dragPosition = 0;
                                  _isFinished = false;
                                });
                              }
                            });
                          } else {
                            // Snap back to starting position
                            setState(() {
                              _dragPosition = 0;
                            });
                          }
                        }
                      : null,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.enabled ? Colors.white : Colors.grey.shade100, // White rounded square thumb
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: widget.enabled
                          ? [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                )
                            ]
                          : [],
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded, // Chevron/arrow matching user image
                      color: widget.enabled ? const Color(0xFF1B3D2F) : Colors.grey.shade400,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
