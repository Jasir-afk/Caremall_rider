import 'dart:io';
import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/delivery_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:care_mall_rider/src/modules/wallet/controller/wallet_controller.dart';

class OrderDetailsScreen extends StatefulWidget {
  /// The order as fetched from the list. The screen will re-fetch the full
  /// detail (including items) using [order.id] on load.
  final DeliveryOrder order;
  const OrderDetailsScreen({super.key, required this.order});

  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  DeliveryOrder? _orderDetail;
  bool _loading = true;
  String? _error;
  bool _hasChanged = false; // Track if status was updated

  bool _paymentCollected = false;
  bool _uploading = false;
  bool _photoUploaded =
      false; // Tracks if photo was uploaded in current session
  bool _updatingStatus = false;

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
      final detail = await OrderRepo.getOrderDetail(widget.order.id);
      if (mounted) setState(() => _orderDetail = detail);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DeliveryOrder get _display => _orderDetail ?? widget.order;

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              AppText(
                text: 'Upload Delivery Photo',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primarylightcolor,
                  radius: 20.r,
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primarycolor,
                    size: 20.sp,
                  ),
                ),
                title: Text('Take Photo', style: TextStyle(fontSize: 16.sp)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F0FE),
                  radius: 20.r,
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: const Color(0xFF4A6CF7),
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16.sp),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    final picked = await picker.pickImage(source: choice, imageQuality: 80);
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _uploading = true);

    final result = await OrderRepo.uploadDeliveryPhoto(
      orderId: widget.order.id,
      photo: File(picked.path),
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (result['success'] == true) {
      setState(() => _photoUploaded = true);
      AppSnackbar.showSuccess(
        title: 'Success',
        message: 'Photo uploaded successfully! You can now deliver.',
      );
    } else {
      AppSnackbar.showError(
        title: 'Upload Failed',
        message: result['message'] ?? 'Upload failed. Try again.',
      );
    }
  }

  Future<void> _markUndelivered() async {
    final TextEditingController reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: AppText(
          text: 'Mark Undelivered',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text:
                  'Please provide a reason for marking this order as undelivered:',
              fontSize: 14.sp,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g., Customer unavailable',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                AppSnackbar.showError(
                  title: 'Error',
                  message: 'Please provide a reason.',
                );
                return;
              }
              Get.back();

              setState(() => _updatingStatus = true);
              final result = await OrderRepo.updateOrderStatus(
                orderId: widget.order.id,
                status: 'undelivered',
                isUndelivered: true,
                undeliveredWarehouseDrop: false,
                note: reason,
              );
              if (mounted) setState(() => _updatingStatus = false);

              if (result['success'] == true) {
                AppSnackbar.showSuccess(
                  title: 'Success',
                  message: 'Order marked as undelivered.',
                );
                _fetchDetail();
                _hasChanged = true;
              } else {
                AppSnackbar.showError(
                  title: 'Error',
                  message: result['message'] ?? 'Failed to update status.',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorMain,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _markWarehouseDrop() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        title: AppText(
          text: 'Confirm Warehouse Drop',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
        content: AppText(
          text:
              'Are you sure you want to mark this order as dropped at warehouse?',
          fontSize: 14.sp,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: AppText(
              text: 'Cancel',
              fontSize: 14.sp,
              color: AppColors.textnaturalcolor,
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarycolor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updatingStatus = true);
    final result = await OrderRepo.markWarehouseDrop(orderId: widget.order.id);
    if (mounted) setState(() => _updatingStatus = false);

    if (result['success'] == true) {
      AppSnackbar.showSuccess(
        title: 'Success',
        message: 'Order dropped at warehouse.',
      );
      _fetchDetail();
      _hasChanged = true;
    } else {
      AppSnackbar.showError(
        title: 'Error',
        message: result['message'] ?? 'Failed to mark warehouse drop.',
      );
    }
  }

  Future<void> _deliverOrder() async {
    // If it's a COD order, ensure payment collected is checked
    final bool isCod = _display.isCod;
    if (isCod && !_paymentCollected) {
      AppSnackbar.showError(
        title: 'Payment Required',
        message: 'Please confirm payment collection for COD order.',
      );
      return;
    }

    // Confirm before marking delivered
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        title: AppText(
          text: 'Confirm Delivery',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
        content: AppText(
          text: 'Mark this order as delivered?',
          fontSize: 14.sp,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarycolor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deliver'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updatingStatus = true);
    final result = await OrderRepo.updateOrderStatus(
      orderId: widget.order.id,
      status: 'delivered',
    );
    if (mounted) setState(() => _updatingStatus = false);

    if (result['success'] == true) {
      AppSnackbar.showSuccess(
        title: 'Success',
        message: 'Order delivered successfully!',
      );
      _fetchDetail();
      _hasChanged = true;
      // Refresh wallet balance
      try {
        if (Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().fetchWalletData();
        }
      } catch (_) {}
    } else {
      AppSnackbar.showError(
        title: 'Error',
        message: result['message'] ?? 'Failed to update status.',
      );
    }
  }

  Future<void> _pickUpOrder() async {
    final source = _display.isFromWarehouse ? 'warehouse' : 'delivery hub';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        title: AppText(
          text: 'Confirm Pickup',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
        content: AppText(
          text: 'Are you picking up this order from the $source?',
          fontSize: 14.sp,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarycolor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updatingStatus = true);
    final result = await OrderRepo.updateOrderStatus(
      orderId: widget.order.id,
      status: 'in_transit',
    );
    if (mounted) setState(() => _updatingStatus = false);

    if (result['success'] == true) {
      AppSnackbar.showSuccess(
        title: 'Success',
        message: 'Order picked up successfully!',
      );
      _fetchDetail();
      _hasChanged = true;
    } else {
      AppSnackbar.showError(
        title: 'Error',
        message: result['message'] ?? 'Failed to update status.',
      );
    }
  }

  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // We don't need to do anything here if using Navigator.pop(context, _hasChanged)
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.all(8.w),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF5F5F5),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context, _hasChanged),
              ),
            ),
          ),
          centerTitle: true,
          title: AppText(
            text: 'Order Details',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textnaturalcolor,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState()
            : _buildContent(_display),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: _fetchDetail,
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
                  Icons.wifi_off_rounded,
                  size: 48.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12.h),
                AppText(
                  text: 'Could not load order details',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]!,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────

  Widget _buildContent(DeliveryOrder order) {
    final bool isCod = order.isCod;
    final bool isCompleted =
        order.orderStatus == 'delivered' ||
        order.orderStatus == 'cancelled' ||
        order.orderStatus == 'failed';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Order ID + status ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        text: 'Order ID : ${order.orderId}',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textnaturalcolor,
                      ),
                    ),
                    _buildStatusBadge(order.orderStatus),
                  ],
                ),
                SizedBox(height: 20.h),

                // ── Customer Details ──────────────────────────────────────
                _buildCustomerCard(order.shippingAddress),
                SizedBox(height: 16.h),

                // ── Payment Details ───────────────────────────────────────
                _buildPaymentCard(isCod, order),
                SizedBox(height: 16.h),

                // ── Dispatch Details ──────────────────────────────────────
                if (order.dispatch != null &&
                    order.orderStatus.toLowerCase() != 'delivered') ...[
                  _buildDispatchCard(order.dispatch!),
                  SizedBox(height: 16.h),
                ],

                // ── Items / Package Details ───────────────────────────────
                if (order.items.isNotEmpty) ...[
                  _buildItemsCard(order.items),
                  SizedBox(height: 24.h),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom Action Buttons ─────────────────────────────────────────
        _buildBottomBar(isCompleted),
      ],
    );
  }

  // ── Status Badge ───────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: _statusBadgeBg(status),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: AppText(
        text: status.replaceAll('_', ' ').toUpperCase(),
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
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
      case 'undelivered':
        return const Color(0xFFFFE3E3);
      case 'shipped':
      case 'out_for_delivery':
      case 'item_picked':
      case 'approved':
      case 'dispatched':
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
      case 'undelivered':
        return const Color(0xFFDC2626);
      case 'shipped':
      case 'out_for_delivery':
      case 'item_picked':
      case 'approved':
      case 'dispatched':
        return const Color(0xFF1A56DB);
      case 'pending':
      case 'requested':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF374151);
    }
  }

  // ── Customer Card ──────────────────────────────────────────────────────────

  Widget _buildCustomerCard(ShippingAddress addr) {
    final address = [
      addr.addressLine1,
      if (addr.addressLine2.isNotEmpty) addr.addressLine2,
      addr.city,
      addr.state,
      addr.postalCode,
      if (addr.landmark.isNotEmpty) 'Near ${addr.landmark}',
    ].where((s) => s.isNotEmpty).join(', ');

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Customer Details'),
          SizedBox(height: 8.h),
          AppText(
            text: addr.fullName,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textnaturalcolor,
          ),
          SizedBox(height: 2.h),
          _infoRow(Icons.phone_outlined, addr.phone),
          SizedBox(height: 4.h),
          _infoRow(Icons.location_on_outlined, address, maxLines: 3),
          SizedBox(height: 16.h),
          _buildOutlineButton(
            icon: Icons.phone_outlined,
            label: 'Call Customer',
            onTap: () async {
              final phone = addr.phone.trim();
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
        ],
      ),
    );
  }

  // ── Payment Card ───────────────────────────────────────────────────────────

  Widget _buildPaymentCard(bool isCod, DeliveryOrder order) {
    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Payment Details'),
                  SizedBox(height: 4.h),
                  AppText(
                    text: 'Payment Method',
                    fontSize: 14.sp,
                    color: AppColors.textnaturalcolor,
                  ),
                ],
              ),
              if (isCod)
                AppText(
                  text: 'Cash on Delivery',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textnaturalcolor,
                )
              else
                AppText(
                  text: 'Pre Paid',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPositiveSecondarycolor,
                ),
            ],
          ),
          if (isCod) ...[
            SizedBox(height: 12.h),
            Divider(color: Colors.grey[200]),
            SizedBox(height: 12.h),
            if (_display.orderStatus.toLowerCase() != 'delivered') ...[
              _detailRow(
                'Order Total',
                '₹ ${order.totalAmount.toStringAsFixed(0)}',
              ),
              SizedBox(height: 8.h),
              _detailRow('COD Charge', '₹ 40'),
              SizedBox(height: 12.h),
              Divider(color: Colors.grey[200]),
              SizedBox(height: 12.h),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: _display.orderStatus.toLowerCase() == 'delivered'
                      ? 'Amount Collected'
                      : 'Amount To Collect',
                  fontSize: 14.sp,
                  color: Colors.grey[600]!,
                ),
                AppText(
                  text: '₹ ${order.amountToCollect.toStringAsFixed(0)}',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _display.orderStatus.toLowerCase() == 'delivered'
                      ? AppColors.textPositiveSecondarycolor
                      : AppColors.ratingYellowcolor,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (_display.isInTransitStatus &&
                !_display.orderStatus.toLowerCase().contains(
                  'undelivered',
                )) ...[
              Divider(color: Colors.grey[200]),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    text: 'Payment Collected',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textnaturalcolor,
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _paymentCollected,
                      onChanged: (val) =>
                          setState(() => _paymentCollected = val),
                      thumbColor: const WidgetStatePropertyAll(Colors.white),
                      trackColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primarycolor;
                        }
                        return Colors.grey[300];
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Dispatch Card ──────────────────────────────────────────────────────────

  Widget _buildDispatchCard(DispatchInfo dispatch) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Dispatch Details'),
          SizedBox(height: 12.h),
          _detailRow(
            'Status',
            dispatch.status.replaceAll('_', ' ').toUpperCase(),
          ),
          SizedBox(height: 8.h),
          _detailRow('Vehicle', dispatch.vehicleNumber),
          SizedBox(height: 8.h),
          _detailRow('Packages', '${dispatch.totalPackages}'),
          SizedBox(height: 8.h),
          _detailRow('Weight', '${dispatch.totalWeight.toStringAsFixed(0)} g'),
          if (dispatch.dispatchDate != null) ...[
            SizedBox(height: 8.h),
            _detailRow(
              'Dispatch Date',
              '${dispatch.dispatchDate!.day}/${dispatch.dispatchDate!.month}/${dispatch.dispatchDate!.year}',
            ),
          ],
          SizedBox(height: 8.h),
          _detailRow('Destination', dispatch.destination),
        ],
      ),
    );
  }

  // ── Items Card ─────────────────────────────────────────────────────────────

  Widget _buildItemsCard(List<OrderItem> items) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Package Details'),
          SizedBox(height: 12.h),
          ...List.generate(items.length, (i) {
            final item = items[i];
            return Column(
              children: [
                if (i > 0) Divider(color: Colors.grey[200], height: 24.h),
                _buildItemRow(item),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: item.productImage != null && item.productImage!.isNotEmpty
              ? Image.network(
                  item.productImage!,
                  width: 54.w,
                  height: 54.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _itemPlaceholder(),
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _itemPlaceholder(isLoading: true);
                  },
                )
              : _itemPlaceholder(),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text:
                    'Product #${item.productId.substring(item.productId.length > 8 ? item.productId.length - 8 : 0)}',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textnaturalcolor,
              ),
              SizedBox(height: 2.h),
              AppText(
                text: 'Qty: ${item.quantity}',
                fontSize: 12.sp,
                color: Colors.grey[500]!,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppText(
              text: '₹ ${item.totalPrice.toStringAsFixed(0)}',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textnaturalcolor,
            ),
            SizedBox(height: 2.h),
            AppText(
              text: 'MRP ₹ ${item.mrpPrice.toStringAsFixed(0)}',
              fontSize: 11.sp,
              color: Colors.grey[400]!,
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemPlaceholder({bool isLoading = false}) {
    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
            )
          : Icon(
              Icons.inventory_2_outlined,
              size: 24.sp,
              color: Colors.grey[400],
            ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isCompleted) {
    if (isCompleted) {
      final isCancelled =
          _display.orderStatus.toLowerCase() == 'cancelled' ||
          _display.orderStatus.toLowerCase() == 'failed';

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: isCancelled
                ? const Color(0xFFFFE3E3)
                : const Color(0xFFE6F4EE),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isCancelled
                  ? const Color(0xFFFFB3B3)
                  : const Color(0xFFB3E0CE),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCancelled ? Icons.cancel_outlined : Icons.check_circle,
                color: isCancelled ? Colors.red : const Color(0xFF1E7E4C),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              AppText(
                text: isCancelled ? 'Cancelled' : 'Delivered',
                color: isCancelled ? Colors.red : const Color(0xFF1E7E4C),
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
      );
    }

    // New Order - Pick up from source
    if (_display.isInNewStatus) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: AppButton(
          onPressed: _updatingStatus ? null : _pickUpOrder,
          btncolor: AppColors.primarycolor,
          borderRadius: 8.r,
          child: _updatingStatus
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
                    Icon(
                      _display.isFromWarehouse
                          ? Icons.inventory_2_outlined
                          : Icons.local_shipping_outlined,
                      size: 20.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.w),
                    AppText(
                      text: _display.isFromWarehouse
                          ? 'Pick From Warehouse'
                          : 'Pick From Delivery Hub',
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
        ),
      );
    }

    final isAlreadyUndelivered =
        _display.orderStatus.toLowerCase() == 'undelivered';
    final isWarehouseDropPending =
        isAlreadyUndelivered &&
        !_display.undeliveredWarehouseDrop &&
        _display.isFromWarehouse;

    // In Transit - Delivery Actions
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isAlreadyUndelivered) ...[
            Expanded(
              child: AppButton(
                onPressed: _updatingStatus ? null : _markUndelivered,
                btncolor: Colors.white,
                borderRadius: 8.r,
                buttonStyle: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  side: WidgetStateProperty.all(
                    const BorderSide(color: AppColors.errorMain),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  elevation: WidgetStateProperty.all(0),
                ),
                child: AppText(
                  text: 'Undelivered',
                  color: AppColors.errorMain,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 12.w),
          ],
          if (isWarehouseDropPending) ...[
            Expanded(
              child: AppButton(
                onPressed: _updatingStatus ? null : _markWarehouseDrop,
                btncolor: AppColors.primarycolor,
                borderRadius: 8.r,
                child: AppText(
                  text: 'Drop at Warehouse',
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 12.w),
          ],
          if (!isAlreadyUndelivered)
            Expanded(
              child: AppButton(
                onPressed: _uploading || _updatingStatus
                    ? null
                    : (_photoUploaded
                          ? (_display.isCod && !_paymentCollected
                                ? null
                                : _deliverOrder)
                          : _uploadPhoto),
                btncolor: AppColors.primarycolor,
                borderRadius: 8.r,
                buttonStyle: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    (_photoUploaded && _display.isCod && !_paymentCollected)
                        ? Colors.grey
                        : AppColors.primarycolor,
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                child: (_uploading || _updatingStatus)
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
                          Icon(
                            _photoUploaded
                                ? Icons.check_circle_outline
                                : Icons.camera_alt_outlined,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6.w),
                          AppText(
                            text: _photoUploaded
                                ? 'Deliver Order'
                                : 'Upload Photo',
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

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
