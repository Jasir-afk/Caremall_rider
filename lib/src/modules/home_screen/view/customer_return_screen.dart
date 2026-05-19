import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/return_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerReturnScreen extends StatefulWidget {
  final ReturnOrder returnOrder;
  const CustomerReturnScreen({super.key, required this.returnOrder});
  @override
  State<CustomerReturnScreen> createState() => _CustomerReturnScreenState();
}

class _CustomerReturnScreenState extends State<CustomerReturnScreen> {
  ReturnOrder? _detail;
  bool _loading = true;
  String? _error;
  bool _updatingStatus = false;
  bool _hasChanged = false;
  bool _detailsConfirmed = false;
  String? _returnMethod; // 'received' or 'dropped'

  @override
  void initState() {
    super.initState();
    _initMethod();
    _fetchDetail();
  }

  void _initMethod() {
    // If not picked yet, default to received
    if (!_display.isPicked) {
      _returnMethod = 'received';
    } else if (!_display.isDropped) {
      // If picked but not dropped, don't auto-select unless it was already the method
      if (_returnMethod != 'dropped') {
        _returnMethod = null;
      }
    } else {
      _returnMethod = null;
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await OrderRepo.getReturnDetail(widget.returnOrder.id);
      if (mounted) {
        setState(() {
          _detail = detail;
          _initMethod();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ReturnOrder get _display => _detail ?? widget.returnOrder;
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Handled directly
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
          title: AppText(
            text: 'Return Collection',
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textnaturalcolor,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey[600]),
              onPressed: _fetchDetail,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 48.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12.h),
                    AppText(
                      text: 'Could not load details',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600]!,
                    ),
                    SizedBox(height: 8.h),
                    TextButton.icon(
                      onPressed: _fetchDetail,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final ret = _display;
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_return_outlined,
                      size: 14.sp,
                      color: const Color(0xFF1A56DB),
                    ),
                    SizedBox(width: 6.w),
                    AppText(
                      text: 'COLLECTION',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(ret.orderStatus),
            ],
          ),
          SizedBox(height: 12.h),
          AppText(
            text: '#${ret.returnId}',
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textnaturalcolor,
          ),
          SizedBox(height: 24.h),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Customer Details'),
                SizedBox(height: 12.h),
                AppText(
                  text: ret.customerName ?? 'No Name',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textnaturalcolor,
                ),
                if (ret.customerPhone != null) ...[
                  SizedBox(height: 6.h),
                  _infoRow(Icons.phone_outlined, ret.customerPhone!),
                ],
                if (ret.address != null) ...[
                  SizedBox(height: 6.h),
                  _infoRow(
                    Icons.location_on_outlined,
                    ret.address!,
                    maxLines: 3,
                  ),
                ],
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: _buildOutlineButton(
                    icon: Icons.phone_outlined,
                    label: 'Call Customer',
                    onTap: () async {
                      final phone = ret.customerPhone?.trim() ?? '';
                      if (phone.isEmpty) return;
                      final uri = Uri(scheme: 'tel', path: phone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMethodButton(
                    'Received',
                    _returnMethod == 'received',
                    ret.isPicked,
                    ((ret.isPicked &&
                                ret.orderStatus.toLowerCase() != 'rejected') ||
                            (ret.returnItemStatus?.toLowerCase() ?? '')
                                .contains('rejected_picked') ||
                            ((ret.returnItemStatus?.toLowerCase() ?? '')
                                    .contains('rejected') &&
                                (ret.returnItemStatus?.toLowerCase() ?? '')
                                    .contains('dropped')))
                        ? null
                        : () => setState(() => _returnMethod = 'received'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _buildMethodButton(
                    'Dropped',
                    _returnMethod == 'dropped',
                    ret.isDropped,
                    ((ret.isDropped &&
                                ret.orderStatus.toLowerCase() != 'rejected') ||
                            (ret.returnItemStatus?.toLowerCase() ?? '')
                                .contains('rejected_dropped'))
                        ? null
                        : () => setState(() => _returnMethod = 'dropped'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Collection Details'),
                SizedBox(height: 12.h),
                _detailRow('ID', ret.returnId),
                SizedBox(height: 10.h),
                _detailRow('Reason', ret.reason ?? 'N/A'),
                if (ret.returnItemStatus != null) ...[
                  SizedBox(height: 10.h),
                  _detailRow(
                    'Item Status',
                    (ret.orderStatus.toLowerCase() == 'rejected' &&
                            !ret.returnItemStatus!.toLowerCase().contains(
                              'rejected',
                            ))
                        ? 'PENDING'
                        : ret.returnItemStatus!
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                    isStatus: true,
                  ),
                ],
                SizedBox(height: 10.h),
                _detailRow(
                  'Date',
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          if ((ret.isDropped == false ||
                  ret.orderStatus.toLowerCase() == 'rejected') &&
              !(ret.orderStatus.toLowerCase() == 'cancelled' ||
                  ret.orderStatus.toLowerCase() == 'failed' ||
                  ret.orderStatus.toLowerCase() == 'completed' ||
                  ret.orderStatus.toLowerCase() == 'refund_completed')) ...[
            _buildConfirmationCard(),
            SizedBox(height: 32.h),
          ] else ...[
            SizedBox(height: 16.h),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodButton(
    String label,
    bool isSelected,
    bool isDone,
    VoidCallback? onTap,
  ) {
    final bool isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : (isDone ? Colors.grey[200] : Colors.transparent),
          borderRadius: BorderRadius.circular(8.r),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDone) ...[
              Icon(Icons.check_circle, size: 14.sp, color: Colors.green),
              SizedBox(width: 4.w),
            ],
            AppText(
              text: label,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primarycolor
                  : (isDone
                        ? Colors.green
                        : (isDisabled ? Colors.grey[400]! : Colors.grey[600]!)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primarylightcolor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primarylightcolor),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _detailsConfirmed = !_detailsConfirmed),
            child: Row(
              children: [
                Icon(
                  _detailsConfirmed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: AppColors.primarycolor,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppText(
                    text: 'I confirm the item has been $_returnMethod.',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textnaturalcolor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed:
                  (_detailsConfirmed &&
                      !_updatingStatus &&
                      _returnMethod != null)
                  ? () => _confirmAction()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarycolor,
                disabledBackgroundColor: AppColors.primarycolor.withValues(
                  alpha: 0.3,
                ),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: _updatingStatus
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : AppText(
                      text: 'Confirm',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction() async {
    if (_returnMethod == null) return;
    final targetStatus = _returnMethod; // 'received' or 'dropped'
    if (targetStatus == null) return;

    try {
      setState(() => _updatingStatus = true);
      final isReceived = targetStatus == 'received';
      final result = await OrderRepo.updateReturnItemStatus(
        returnId: widget.returnOrder.id,
        returnItemStatus: targetStatus,
        pickupStatus: !isReceived ? 'item_delivered' : null,
        isPicked: isReceived ? true : null,
        isDropped: !isReceived ? true : null,
      );

      if (mounted) {
        if (result['success'] == true) {
          AppSnackbar.showSuccess(
            title: 'Success',
            message:
                'Item status updated to ${targetStatus.replaceAll('_', ' ').toUpperCase()}!',
          );
          _fetchDetail();
          _hasChanged = true;
          setState(() {
            _detailsConfirmed = false;
          });
        } else {
          AppSnackbar.showError(
            title: 'Update Failed',
            message: result['message'] ?? 'Update failed.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(title: 'Error', message: 'An error occurred: $e');
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: _statusBadgeBg(status),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: AppText(
        text: status.replaceAll('_', ' ').toUpperCase(),
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: _statusBadgeFg(status),
      ),
    );
  }

  Color _statusBadgeBg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'refund_completed':
      case 'item_received':
      case 'received':
      case 'refunded':
      case 'dropped':
        return const Color(0xFFE6F4EE);
      case 'cancelled':
      case 'failed':
      case 'rejected':
      case 'not_applicable':
      case 'rejected_picked':
      case 'rejected_dropped':
      case 'rejected_sent':
      case 'rejected_received':
        return const Color(0xFFFFE3E3);
      case 'shipped':
      case 'out_for_delivery':
      case 'item_picked':
      case 'approved':
      case 'picked':
      case 'sent':
        return const Color(0xFFE8F0FE);
      case 'pending':
      case 'requested':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _statusBadgeFg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'refund_completed':
      case 'item_received':
      case 'received':
      case 'refunded':
      case 'dropped':
        return const Color(0xFF1E7E4C);
      case 'cancelled':
      case 'failed':
      case 'rejected':
      case 'not_applicable':
      case 'rejected_picked':
      case 'rejected_dropped':
      case 'rejected_sent':
      case 'rejected_received':
        return const Color(0xFFDC2626);
      case 'shipped':
      case 'out_for_delivery':
      case 'item_picked':
      case 'picked':
      case 'sent':
        return AppColors.primarycolor;
      case 'pending':
      case 'requested':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF374151);
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return AppText(
      text: text,
      fontSize: 12.sp,
      color: Colors.grey[500]!,
      fontWeight: FontWeight.w500,
    );
  }

  Widget _infoRow(IconData icon, String text, {int maxLines = 2}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.sp, color: Colors.grey[500]),
        SizedBox(width: 6.w),
        Expanded(
          child: AppText(
            text: text,
            fontSize: 13.sp,
            color: Colors.grey[600]!,
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(text: label, fontSize: 13.sp, color: Colors.grey[500]!),
        SizedBox(width: 12.w),
        Flexible(
          child: AppText(
            text: value,
            fontSize: 13.sp,
            fontWeight: isStatus ? FontWeight.w700 : FontWeight.w600,
            color: isStatus
                ? const Color(0xFF1A56DB)
                : AppColors.textnaturalcolor,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildOutlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: Colors.grey[600]),
            SizedBox(width: 6.w),
            AppText(
              text: label,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textnaturalcolor,
            ),
          ],
        ),
      ),
    );
  }
}
