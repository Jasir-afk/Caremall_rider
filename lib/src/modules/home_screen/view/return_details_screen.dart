import 'dart:io';
import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/return_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:care_mall_rider/src/modules/wallet/controller/wallet_controller.dart';

class ReturnDetailsScreen extends StatefulWidget {
  /// The lightweight return order card from the list – used for immediate
  /// display while the full detail is loading.
  final ReturnOrder returnOrder;

  const ReturnDetailsScreen({super.key, required this.returnOrder});

  @override
  State<ReturnDetailsScreen> createState() => _ReturnDetailsScreenState();
}

class _ReturnDetailsScreenState extends State<ReturnDetailsScreen> {
  ReturnOrder? _detail;
  bool _loading = true;
  String? _error;
  bool _updatingStatus = false;
  bool _uploading = false;
  bool _photoUploaded = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await OrderRepo.getReturnDetail(widget.returnOrder.id);
      if (mounted) setState(() => _detail = detail);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String status, {String? pickupStatus}) async {
    setState(() => _updatingStatus = true);
    try {
      final result = await OrderRepo.updateReturnStatus(
        returnId: widget.returnOrder.id,
        status: status,
        pickupStatus: pickupStatus,
      );
      if (mounted) {
        if (result['success'] == true) {
          AppSnackbar.showSuccess(
            title: 'Success',
            message: 'Status updated to ${status.replaceAll('_', ' ')}!',
          );
        } else {
          AppSnackbar.showError(
            title: 'Update Failed',
            message: result['message'] ?? 'Update failed.',
          );
        }
        if (result['success'] == true) {
          _fetchDetail();
          _hasChanged = true;

          // Refresh wallet balance
          try {
            if (Get.isRegistered<WalletController>()) {
              Get.find<WalletController>().fetchWalletData();
            }
          } catch (e) {
            // Silently fail if controller not available
          }
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

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    final picked = await picker.pickImage(source: choice, imageQuality: 80);
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _uploading = true);

    final result = await OrderRepo.uploadReturnPhoto(
      returnId: widget.returnOrder.id,
      photo: File(picked.path),
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (result['success'] == true) {
      setState(() => _photoUploaded = true);
      AppSnackbar.showSuccess(
        title: 'Success',
        message: 'Photo uploaded successfully!',
      );
    } else {
      AppSnackbar.showError(
        title: 'Upload Failed',
        message: result['message'] ?? 'Upload failed. Try again.',
      );
    }
  }

  ReturnOrder get _display => _detail ?? widget.returnOrder;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Handled by manual Navigator.pop
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
            text: 'Return Details',
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
          // ── Return ID + Status ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppText(
                  text: 'Return #${ret.returnId}',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textnaturalcolor,
                ),
              ),
              _buildStatusBadge(ret.orderStatus),
            ],
          ),
          SizedBox(height: 20.h),

          // ── Customer Card ─────────────────────────────────────────────────
          if (ret.customerName != null || ret.customerPhone != null) ...[
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Customer Details'),
                  SizedBox(height: 8.h),
                  if (ret.customerName != null)
                    AppText(
                      text: ret.customerName!,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textnaturalcolor,
                    ),
                  if (ret.customerPhone != null) ...[
                    SizedBox(height: 4.h),
                    _infoRow(Icons.phone_outlined, ret.customerPhone!),
                  ],
                  if (ret.address != null) ...[
                    SizedBox(height: 4.h),
                    _infoRow(
                      Icons.location_on_outlined,
                      ret.address!,
                      maxLines: 3,
                    ),
                  ],
                  SizedBox(height: 16.h),
                  if (ret.customerPhone != null)
                    SizedBox(
                      width: double.infinity,
                      child: _buildOutlineButton(
                        icon: Icons.phone_outlined,
                        label: 'Call Customer',
                        onTap: () async {
                          final phone = ret.customerPhone!.trim();
                          if (phone.isEmpty) return;
                          final uri = Uri(scheme: 'tel', path: phone);
                          try {
                            await launchUrl(uri);
                          } catch (_) {
                            if (mounted) {
                              AppSnackbar.showError(
                                title: 'Error',
                                message: 'Could not launch dialler.',
                              );
                            }
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // ── Return Info Card ──────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Return Details'),
                SizedBox(height: 12.h),
                _detailRow('Return ID', ret.returnId),
                if (ret.reason != null) ...[
                  SizedBox(height: 8.h),
                  _detailRow('Reason', ret.reason!),
                ],
                SizedBox(height: 8.h),
                _detailRow(
                  'Status',
                  ret.orderStatus.replaceAll('_', ' ').toUpperCase(),
                ),
                if (ret.createdAt != null) ...[
                  SizedBox(height: 8.h),
                  _detailRow(
                    'Date',
                    '${ret.createdAt!.day}/${ret.createdAt!.month}/${ret.createdAt!.year}',
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // ── Amount Card ───────────────────────────────────────────────────
          _buildCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: 'Refund Amount',
                  fontSize: 14.sp,
                  color: Colors.grey[600]!,
                ),
                AppText(
                  text: '₹ ${ret.totalAmount.toStringAsFixed(0)}',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textnaturalcolor,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // ── Action Button ─────────────────────────────────────────────────
          _buildActionButton(),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final status = _display.orderStatus.toLowerCase();
    String? nextStatus;
    String? label;
    IconData? icon;

    if (status == 'pending' || status == 'confirmed') {
      if (_photoUploaded) {
        nextStatus = 'item_picked';
        label = 'Mark as Picked';
        icon = Icons.local_shipping_outlined;
      } else {
        label = 'Upload Photo';
        icon = Icons.camera_alt_outlined;
      }
    } else if (status == 'item_picked') {
      nextStatus = 'item_received';
      label = 'Mark as Received';
      icon = Icons.inventory_2_outlined;
    }

    if (label == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: AppButton(
        onPressed: (_updatingStatus || _uploading)
            ? null
            : (nextStatus == null
                  ? _uploadPhoto
                  : () => _updateStatus(
                      nextStatus!,
                      pickupStatus: nextStatus == 'item_picked'
                          ? 'item_picked'
                          : null,
                    )),
        btncolor: AppColors.primarycolor,
        borderRadius: 8.r,
        buttonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.primarycolor),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
        child: (_updatingStatus || _uploading)
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16.sp, color: Colors.white),
                  SizedBox(width: 8.w),
                  AppText(
                    text: label,
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
      ),
    );
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

  Color _statusBadgeFg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'refund_completed':
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

  Widget _detailRow(String label, String value) {
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
            fontWeight: FontWeight.w600,
            color: AppColors.textnaturalcolor,
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
