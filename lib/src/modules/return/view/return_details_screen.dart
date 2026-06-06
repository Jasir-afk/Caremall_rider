import 'package:care_mall_rider/app/commenwidget/app_snackbar.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/src/modules/return/controller/return_repo.dart';
import 'package:care_mall_rider/src/modules/return/model/return_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ReturnDetailsScreen extends StatefulWidget {
  final ReturnOrder returnOrder;

  const ReturnDetailsScreen({super.key, required this.returnOrder});

  State<ReturnDetailsScreen> createState() => _ReturnDetailsScreenState();
}

class _ReturnDetailsScreenState extends State<ReturnDetailsScreen>
    with SingleTickerProviderStateMixin {
  ReturnOrder? _detail;
  bool _loading = true;
  String? _error;
  bool _updatingStatus = false;
  bool _hasChanged = false;
  bool _detailsConfirmed = false;
  String? _returnMethod;
  bool _replacementAllowed = false;
  bool _hubPickConfirmed = false; // true after rider confirms pickup from hub

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFFF6F6F8);
  static const Color _surface = Colors.white;
  static const Color _divider = Color(0xFFEDEDED);
  static const Color _labelGrey = Color(0xFF9E9E9E);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _green = Color(0xFF0BAB64);
  static const Color _orange = Color(0xFFFF8C00);
  static const Color _red = Color(0xFFE53935);
  static const Color _blue = Color(0xFF1565C0);

  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fetchDetail();
  }

  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ReturnRepo.getReturnDetail(widget.returnOrder.id);
      if (mounted) {
        setState(() {
          _detail = detail;
          final serverReplStatus = detail.replacementDeliveryStatus
              ?.toLowerCase();
          if (serverReplStatus != 'received') {
            _hubPickConfirmed = false; // safe to reset, server has moved on
          }
          // else: keep _hubPickConfirmed = true so UI stays on drop_off step
          final isRejected = detail.orderStatus.toLowerCase().contains(
            'rejected',
          );
          final replStatus = detail.replacementDeliveryStatus?.toLowerCase();
          _replacementAllowed =
              detail.returnType?.toLowerCase() == 'replacement' &&
              !isRejected &&
              detail.isDropped &&
              (replStatus == 'received' ||
                  replStatus == 'picked' ||
                  replStatus == 'completed' ||
                  replStatus == 'delivered');
          _initMethod();
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initMethod() {
    final ret = _display;
    final orderStatus = ret.orderStatus.toLowerCase();
    if (orderStatus == 'completed' ||
        orderStatus == 'refund_completed' ||
        orderStatus == 'returned' ||
        orderStatus == 'refunded' ||
        orderStatus == 'return_completed' ||
        orderStatus == 'cancelled' ||
        orderStatus == 'failed') {
      _returnMethod = null;
      return;
    }

    final isReplacement = ret.returnType?.toLowerCase() == 'replacement';
    final isDropped = ret.isDropped;
    final isPicked = ret.isPicked;
    final replStatus = ret.replacementDeliveryStatus?.toLowerCase();
    final itemStatus = (ret.returnItemStatus?.toLowerCase() ?? '').replaceAll(
      ' ',
      '_',
    );
    final isRejected = ret.orderStatus.toLowerCase().contains('rejected');

    if (isReplacement && isRejected) {
      final isRejectedReceived =
          ret.orderStatus.toLowerCase() == 'rejected_received' ||
          itemStatus == 'rejected_received';
      if (itemStatus.contains('rejected_dropped')) {
        _returnMethod = null;
      } else if (itemStatus.contains('rejected_picked')) {
        _returnMethod = 'drop_off';
      } else if (isRejectedReceived) {
        _returnMethod = 'pickup';
      } else {
        _returnMethod = null;
      }
    } else if (isReplacement) {
      if (_replacementAllowed) {
        // Phase 2: hub → customer
        if (replStatus == 'completed' ||
            replStatus == 'delivered' ||
            orderStatus == 'completed') {
          _returnMethod = null; // Delivered — done
        } else if (replStatus == 'picked' || _hubPickConfirmed) {
          _returnMethod = 'drop_off'; // Picked from hub → deliver to customer
          _detailsConfirmed = false; // reset checkbox for next step
        } else {
          _returnMethod = 'pickup'; // 'received' → rider must pick first
        }
      } else {
        // Phase 1: customer → hub
        if (!isPicked) {
          _returnMethod = 'pickup';
        } else if (!isDropped) {
          _returnMethod = 'drop_off';
        } else {
          _returnMethod = null;
        }
      }
    } else if (isRejected) {
      final isRejectedReceived =
          ret.orderStatus.toLowerCase() == 'rejected_received' ||
          itemStatus == 'rejected_received';
      if (itemStatus == 'rejected_dropped') {
        _returnMethod = null;
      } else if (itemStatus == 'rejected_picked') {
        _returnMethod = 'drop_off';
      } else if (isRejectedReceived) {
        _returnMethod = 'pickup';
      } else {
        _returnMethod = null;
      }
    } else {
      if (!isPicked) {
        _returnMethod = 'pickup';
      } else if (!isDropped) {
        _returnMethod = 'drop_off';
      } else {
        _returnMethod = null;
      }
    }
  }

  ReturnOrder get _display => _detail ?? widget.returnOrder;

  // ── Step helpers ──────────────────────────────────────────────────────────
  int get _currentStep {
    final ret = _display;
    final isReplacement = ret.returnType?.toLowerCase() == 'replacement';
    final replStatus = ret.replacementDeliveryStatus?.toLowerCase();
    final orderStatus = ret.orderStatus.toLowerCase();
    final itemStatus = (ret.returnItemStatus?.toLowerCase() ?? '').replaceAll(
      ' ',
      '_',
    );
    final isRejected = orderStatus.contains('rejected');

    if (isReplacement && isRejected) {
      if (itemStatus.contains('rejected_dropped')) return 3;
      if (itemStatus.contains('rejected_picked')) return 1;
      if (orderStatus == 'rejected_received' ||
          itemStatus == 'rejected_received') {
        return 0;
      }
      return -1;
    }

    if (isRejected) {
      if (itemStatus == 'rejected_dropped' || itemStatus == 'item_delivered') {
        return 2;
      }
      if (itemStatus == 'rejected_picked') return 1;
      if (orderStatus == 'rejected_received' ||
          itemStatus == 'rejected_received') {
        return 0;
      }
      return -1;
    }

    // ── Replacement delivery phase (hub → customer)
    if (isReplacement && ret.isDropped && _replacementAllowed) {
      if (replStatus == 'completed' ||
          replStatus == 'delivered' ||
          orderStatus == 'completed') {
        return 2;
      }
      if (replStatus == 'picked' || _hubPickConfirmed) {
        return 1; // picked from hub
      }
      return 0; // 'received' → not started yet
    }

    // ── Replacement collection phase (customer → hub)
    if (isReplacement && !ret.isDropped) {
      if (itemStatus == 'sent') return 2;
      if (ret.isPicked) return 1;
      return 0;
    }

    // ── Replacement: item at hub, awaiting admin approval
    if (isReplacement && ret.isDropped && !_replacementAllowed) {
      return 2;
    }

    if (orderStatus == 'completed' ||
        orderStatus == 'refund_completed' ||
        orderStatus == 'returned' ||
        orderStatus == 'refunded' ||
        orderStatus == 'return_completed' ||
        replStatus == 'delivered' ||
        itemStatus == 'item_delivered') {
      return 3;
    }

    if (ret.isDropped || itemStatus == 'sent') return 2;
    if (ret.isPicked) return 1;
    return 0;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  Widget build(BuildContext context) {
    final isReplacement =
        (_detail?.returnType?.toLowerCase() == 'replacement' ||
        widget.returnOrder.returnType?.toLowerCase() == 'replacement');
    final title = '${isReplacement ? 'Replacement' : 'Refund'} Details';

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: _buildAppBar(title),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primarycolor,
                ),
              )
            : _error != null
            ? _buildError()
            : FadeTransition(opacity: _fadeAnim, child: _buildContent()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: _textDark,
        ),
        onPressed: () => Navigator.pop(context, _hasChanged),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '#${_display.returnId}',
            style: TextStyle(
              fontSize: 11.sp,
              color: _labelGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
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
                  Icons.cloud_off_rounded,
                  size: 52.sp,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 16.h),
                Text(
                  'Could not load details',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Check your connection and try again.',
                  style: TextStyle(fontSize: 13.sp, color: _labelGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final ret = _display;
    final replStatus = _display.replacementDeliveryStatus?.toLowerCase();
    final isReplacementPhase2 =
        _display.returnType?.toLowerCase() == 'replacement' &&
        _display.isDropped &&
        _replacementAllowed;

    final bool showConfirm =
        !(_display.orderStatus.toLowerCase() == 'cancelled' ||
            _display.orderStatus.toLowerCase() == 'failed' ||
            _display.orderStatus.toLowerCase() == 'completed' ||
            _display.orderStatus.toLowerCase() == 'refund_completed' ||
            _display.orderStatus.toLowerCase() == 'returned' ||
            _display.orderStatus.toLowerCase() == 'refunded' ||
            _display.orderStatus.toLowerCase() == 'return_completed') &&
        (
        // Phase 2 replacement delivery: show when replStatus is 'received' or 'picked'
        (isReplacementPhase2 &&
                (replStatus == 'received' ||
                    replStatus == 'picked' ||
                    _hubPickConfirmed)) ||
            // Standard refund: not yet dropped
            (!_display.isDropped &&
                _display.returnType?.toLowerCase() != 'replacement' &&
                !_display.orderStatus.toLowerCase().contains('rejected')) ||
            // Rejected flow: has a pending action
            (_display.orderStatus.toLowerCase().contains('rejected') &&
                _returnMethod != null) ||
            // Phase 1 replacement collection: not yet dropped at hub
            (_display.returnType?.toLowerCase() == 'replacement' &&
                !_replacementAllowed &&
                _returnMethod != null));

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHero(ret),
                SizedBox(height: 16.h),
                _buildTimeline(ret),
                SizedBox(height: 16.h),
                _buildCustomerCard(ret),
                SizedBox(height: 12.h),
                _buildReturnInfoCard(ret),
                SizedBox(height: 12.h),
                if (ret.order != null) _buildOrderInfoCard(ret),
                if (ret.order != null) SizedBox(height: 12.h),
                if (_returnMethod != null) ...[
                  _buildMethodSelector(ret),
                  SizedBox(height: 12.h),
                ],
                _buildAmountCard(ret),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
        if (showConfirm) _buildStickyConfirm(),
      ],
    );
  }

  // ── Status Hero ────────────────────────────────────────────────────────────
  Widget _buildStatusHero(ReturnOrder ret) {
    final isReplacement = ret.returnType?.toLowerCase() == 'replacement';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: isReplacement
                  ? const Color(0xFFE8F0FE)
                  : AppColors.primarylightcolor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isReplacement
                  ? Icons.swap_horiz_rounded
                  : Icons.assignment_return_rounded,
              color: isReplacement ? _blue : AppColors.primarycolor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isReplacement ? 'REPLACEMENT' : 'REFUND',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isReplacement ? _blue : AppColors.primarycolor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _buildStatusPill(ret.orderStatus),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '#${ret.returnId}',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                if (ret.createdAt != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    _formatDate(ret.createdAt!),
                    style: TextStyle(fontSize: 11.sp, color: _labelGrey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────────
  Widget _buildTimeline(ReturnOrder ret) {
    final isReplacement = ret.returnType?.toLowerCase() == 'replacement';
    final isRejected = ret.orderStatus.toLowerCase().contains('rejected');
    final step = _currentStep;

    List<_TimelineStep> steps;

    if (isReplacement && isRejected) {
      steps = [
        _TimelineStep(
          icon: Icons.warehouse_outlined,
          label: 'Picked from Hub',
          sublabel: 'Collect item',
          done: step >= 1,
          active: step == 0,
        ),
        _TimelineStep(
          icon: Icons.person_pin_circle_outlined,
          label: 'Returned to Customer',
          sublabel: 'Item returned',
          done: step >= 2,
          active: step == 1,
        ),
        _TimelineStep(
          icon: Icons.cancel_outlined,
          label: 'Rejected Closed',
          sublabel: 'Case closed',
          done: step >= 3,
          active: step == 2,
        ),
      ];
    } else if (isRejected) {
      steps = [
        _TimelineStep(
          icon: Icons.warehouse_outlined,
          label: 'Pick from Hub',
          sublabel: 'Collect item',
          done: step >= 1,
          active: step == 0,
        ),
        _TimelineStep(
          icon: Icons.person_pin_circle_outlined,
          label: 'Delivered',
          sublabel: 'Back to customer',
          done: step >= 2,
          active: step == 1,
        ),
      ];
    } else if (isReplacement && ret.isDropped && _replacementAllowed) {
      // ── Replacement delivery phase: 2-step (hub → customer)
      steps = [
        _TimelineStep(
          icon: Icons.warehouse_outlined,
          label: 'Picked from Hub',
          sublabel: 'Item collected',
          done: step >= 1,
          active: step == 0,
        ),
        _TimelineStep(
          icon: Icons.person_pin_circle_outlined,
          label: 'Delivered',
          sublabel: 'Customer received',
          done: step >= 2,
          active: step == 1,
        ),
      ];
    } else if (isReplacement && !ret.isDropped) {
      steps = [
        _TimelineStep(
          icon: Icons.directions_walk_rounded,
          label: 'Picked from Customer',
          sublabel: 'From customer',
          done: step >= 1,
          active: step == 0,
        ),
        _TimelineStep(
          icon: Icons.warehouse_outlined,
          label: 'Dropped at Hub',
          sublabel: 'Hub received',
          done: step >= 2,
          active: step == 1,
        ),
      ];
    } else if (isReplacement && ret.isDropped && !_replacementAllowed) {
      steps = [
        _TimelineStep(
          icon: Icons.directions_walk_rounded,
          label: 'Picked from Customer',
          sublabel: 'From customer',
          done: true,
          active: false,
        ),
        _TimelineStep(
          icon: Icons.warehouse_outlined,
          label: 'Dropped at Hub',
          sublabel: 'Hub received',
          done: true,
          active: false,
        ),
      ];
    } else {
      steps = [
        _TimelineStep(
          icon: Icons.person_pin_circle_outlined,
          label: 'Picked Up',
          sublabel: 'From customer',
          done: step >= 1,
          active: step == 0,
        ),
        _TimelineStep(
          icon: Icons.warehouse_outlined,
          label: 'Dropped at Hub',
          sublabel: 'Hub received',
          done: step >= 2,
          active: step == 1,
        ),
        _TimelineStep(
          icon: Icons.check_circle_outline_rounded,
          label: 'Completed',
          sublabel: 'Process done',
          done: step >= 3,
          active: step == 2,
        ),
      ];
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: _labelGrey,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIdx = i ~/ 2;
                final filled = step > stepIdx;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.only(bottom: 18.h),
                    decoration: BoxDecoration(
                      color: filled ? _green : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final s = steps[i ~/ 2];
              return _buildTimelineNode(s);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(_TimelineStep s) {
    final Color color = s.done
        ? _green
        : s.active
        ? AppColors.primarycolor
        : const Color(0xFFDDDDDD);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: s.done
                ? const Color(0xFFE8F5EE)
                : s.active
                ? AppColors.primarylightcolor
                : const Color(0xFFF4F4F4),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: s.active ? 2 : 1.5),
          ),
          child: Icon(s.icon, size: 16.sp, color: color),
        ),
        SizedBox(height: 6.h),
        Text(
          s.label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: s.active || s.done ? FontWeight.w700 : FontWeight.w400,
            color: s.done
                ? _green
                : s.active
                ? _textDark
                : _labelGrey,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          s.sublabel,
          style: TextStyle(fontSize: 9.sp, color: _labelGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Customer Card ──────────────────────────────────────────────────────────
  Widget _buildCustomerCard(ReturnOrder ret) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Customer', Icons.person_outline_rounded),
          SizedBox(height: 14.h),
          Text(
            ret.customerName ?? 'Unknown',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          SizedBox(height: 10.h),
          if (ret.customerPhone != null)
            _iconRow(
              Icons.call_outlined,
              ret.customerPhone!,
              color: AppColors.primarycolor,
            ),
          if (ret.address != null) ...[
            SizedBox(height: 8.h),
            _iconRow(Icons.location_on_outlined, ret.address!, maxLines: 3),
          ],
          SizedBox(height: 14.h),
          _tappableButton(
            icon: Icons.call_rounded,
            label: 'Call Customer',
            color: AppColors.primarycolor,
            onTap: () async {
              final phone = ret.customerPhone?.trim() ?? '';
              if (phone.isEmpty) {
                AppSnackbar.showError(
                  title: 'Invalid Number',
                  message: 'Customer phone number is not available.',
                );
                return;
              }
              final uri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                AppSnackbar.showError(
                  title: 'Error',
                  message: 'Could not open the phone dialer.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Pick / Drop Selector ──────────────────────────────────────────────────
  Widget _buildMethodSelector(ReturnOrder ret) {
    final isReplacement = ret.returnType?.toLowerCase() == 'replacement';
    final isDropped = ret.isDropped;
    final isPicked = ret.isPicked;
    final isRejected = ret.orderStatus.toLowerCase().contains('rejected');
    final replStatus = ret.replacementDeliveryStatus?.toLowerCase();

    bool canTapPicked = false;
    bool isPickedDone = false;
    bool canTapDropped = false;
    bool isDroppedDone = false;
    String pickedLabel;
    String droppedLabel;
    IconData pickedIcon;
    IconData droppedIcon;

    if (isReplacement && isRejected) {
      final isRejectedReceived =
          ret.orderStatus.toLowerCase() == 'rejected_received' ||
          (ret.returnItemStatus?.toLowerCase() ?? '') == 'rejected_received';
      pickedLabel = 'Picked from Hub';
      droppedLabel = 'Returned to Customer';
      pickedIcon = Icons.warehouse_outlined;
      droppedIcon = Icons.person_pin_circle_rounded;
      final normStatus = (ret.returnItemStatus?.toLowerCase() ?? '').replaceAll(
        ' ',
        '_',
      );
      isPickedDone =
          normStatus == 'rejected_picked' || normStatus == 'rejected_dropped';
      isDroppedDone = normStatus == 'rejected_dropped';
      canTapPicked = isRejectedReceived && !isPickedDone;
      canTapDropped = isRejectedReceived && isPickedDone && !isDroppedDone;
    } else if (isReplacement) {
      if (_replacementAllowed) {
        // Phase 2: hub → customer
        // 'received' = hub ready, rider NOT yet picked → show pickup button
        // 'picked'   = rider confirmed pickup → show deliver button
        pickedLabel = 'Picked from Hub';
        droppedLabel = 'Delivered to Customer';
        pickedIcon = Icons.warehouse_outlined;
        droppedIcon = Icons.person_pin_circle_rounded;
        isPickedDone =
            _hubPickConfirmed || // local guard after first tap
            replStatus == 'picked' ||
            replStatus == 'completed' ||
            replStatus == 'delivered';
        isDroppedDone = replStatus == 'completed' || replStatus == 'delivered';
        canTapPicked =
            replStatus == 'received' && !isPickedDone; // active when 'received'
        canTapDropped = isPickedDone && !isDroppedDone;
      } else {
        // Phase 1: customer → hub
        pickedLabel = 'Picked from Customer';
        droppedLabel = 'Dropped at Hub';
        pickedIcon = Icons.directions_walk_rounded;
        droppedIcon = Icons.warehouse_outlined;
        isPickedDone = isPicked;
        isDroppedDone = isDropped;
        canTapPicked = !isPicked;
        canTapDropped = isPicked && !isDropped;
      }
    } else if (isRejected) {
      pickedLabel = 'Pick from Hub';
      droppedLabel = 'Delivered';
      pickedIcon = Icons.warehouse_rounded;
      droppedIcon = Icons.person_pin_circle_rounded;
      final itemStatus = (ret.returnItemStatus?.toLowerCase() ?? '').replaceAll(
        ' ',
        '_',
      );
      final isRejectedReceived =
          ret.orderStatus.toLowerCase() == 'rejected_received' ||
          itemStatus == 'rejected_received';
      isPickedDone =
          itemStatus == 'rejected_picked' || itemStatus == 'rejected_dropped';
      isDroppedDone = itemStatus == 'rejected_dropped';
      canTapPicked = isRejectedReceived && !isPickedDone;
      canTapDropped = isRejectedReceived && isPickedDone && !isDroppedDone;
    } else {
      pickedLabel = 'Picked Up';
      droppedLabel = 'Dropped at Hub';
      pickedIcon = Icons.directions_walk_rounded;
      droppedIcon = Icons.local_shipping_outlined;
      final itemStatus = (ret.returnItemStatus?.toLowerCase() ?? '').replaceAll(
        ' ',
        '_',
      );
      final effectivelyDropped = isDropped || itemStatus == 'sent';
      isPickedDone = isPicked || effectivelyDropped;
      isDroppedDone = effectivelyDropped;
      canTapPicked = !isPickedDone;
      canTapDropped = isPickedDone && !isDroppedDone;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Action', Icons.touch_app_outlined),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                _segmentBtn(
                  label: pickedLabel,
                  icon: pickedIcon,
                  selected: !isPickedDone && _returnMethod == 'pickup',
                  done: isPickedDone,
                  enabled: canTapPicked && !isPickedDone,
                  onTap: canTapPicked && !isPickedDone
                      ? () => setState(() => _returnMethod = 'pickup')
                      : null,
                ),
                SizedBox(width: 4.w),
                _segmentBtn(
                  label: droppedLabel,
                  icon: droppedIcon,
                  selected: !isDroppedDone && _returnMethod == 'drop_off',
                  done: isDroppedDone,
                  enabled: canTapDropped && !isDroppedDone,
                  onTap: canTapDropped && !isDroppedDone
                      ? () => setState(() => _returnMethod = 'drop_off')
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentBtn({
    required String label,
    required IconData icon,
    required bool selected,
    required bool done,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    final Color fg = selected
        ? AppColors.primarycolor
        : done
        ? _green
        : enabled
        ? _textDark
        : _labelGrey;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46.h,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done)
                Icon(Icons.check_circle_rounded, size: 14.sp, color: _green)
              else
                Icon(icon, size: 15.sp, color: fg),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Return Info Card ───────────────────────────────────────────────────────
  Widget _buildReturnInfoCard(ReturnOrder ret) {
    final isReplacement = ret.returnType?.toLowerCase() == 'replacement';
    final isRejected = ret.orderStatus.toLowerCase().contains('rejected');
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            isReplacement ? 'Replacement Info' : 'Refund Info',
            Icons.info_outline_rounded,
          ),
          SizedBox(height: 14.h),
          _kv('${isReplacement ? 'Replacement' : 'Refund'} ID', ret.returnId),
          _dividerLine(),
          _kv('Reason', ret.reason ?? 'N/A'),
          // Hide returnItemStatus during replacement delivery phase 2
          // to avoid confusing rider with phase 1 'dropped' status
          if (ret.returnItemStatus != null &&
              !(_replacementAllowed &&
                  (ret.replacementDeliveryStatus?.toLowerCase() == 'picked' ||
                      ret.replacementDeliveryStatus?.toLowerCase() ==
                          'completed' ||
                      ret.replacementDeliveryStatus?.toLowerCase() ==
                          'delivered'))) ...[
            _dividerLine(),
            _kv(
              'Item Status',
              (ret.orderStatus.toLowerCase().contains('rejected') &&
                      !ret.returnItemStatus!.toLowerCase().contains('rejected'))
                  ? 'PENDING'
                  : ret.returnItemStatus!.replaceAll('_', ' ').toUpperCase(),
              isStatus: true,
              statusText: ret.returnItemStatus!,
            ),
          ],
          if (!isReplacement && !isRejected && ret.pickStatus != null) ...[
            _dividerLine(),
            _kv(
              'Pick Status',
              ret.pickStatus!.replaceAll('_', ' ').toUpperCase(),
              isStatus: true,
              statusText: ret.pickStatus!,
            ),
          ],
          if (isReplacement &&
              !isRejected &&
              ret.replacementDeliveryStatus != null) ...[
            _dividerLine(),
            _kv(
              'Replacement Status',
              ret.replacementDeliveryStatus!.replaceAll('_', ' ').toUpperCase(),
              isStatus: true,
              statusText: ret.replacementDeliveryStatus!,
            ),
          ],
          if (!isReplacement && ret.refundStatus != null) ...[
            _dividerLine(),
            _kv(
              'Refund Status',
              ret.refundStatus!.replaceAll('_', ' ').toUpperCase(),
              isStatus: true,
              statusText: ret.refundStatus!,
            ),
          ],
        ],
      ),
    );
  }

  // ── Amount Card ────────────────────────────────────────────────────────────
  Widget _buildAmountCard(ReturnOrder ret) {
    final isReplacement = ret.returnType?.toLowerCase() == 'replacement';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primarycolor, const Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primarycolor.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReplacement ? 'TOTAL AMOUNT' : 'REFUND AMOUNT',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '₹${ret.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReplacement
                  ? Icons.swap_horiz_rounded
                  : Icons.currency_rupee_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Order Info Card ────────────────────────────────────────────────────────
  Widget _buildOrderInfoCard(ReturnOrder ret) {
    final order = ret.order!;
    final orderId =
        order['orderId']?.toString() ?? order['_id']?.toString() ?? '—';
    final paymentMethod =
        order['paymentMethod']?.toString().toUpperCase() ?? '—';
    final orderAmt = order['totalAmount'] != null
        ? '₹${double.tryParse(order['totalAmount'].toString())?.toStringAsFixed(0) ?? '—'}'
        : '—';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Order Details', Icons.receipt_long_outlined),
          SizedBox(height: 14.h),
          _kv('Order ID', '#$orderId'),
          _dividerLine(),
          _kv('Payment', paymentMethod),
          _dividerLine(),
          _kv('Order Amount', orderAmt),
        ],
      ),
    );
  }

  // ── Confirm label helper ───────────────────────────────────────────────────
  String _buildConfirmLabel() {
    final isReplacement = _display.returnType?.toLowerCase() == 'replacement';
    final isRejected = _display.orderStatus.toLowerCase().contains('rejected');

    if (isReplacement && isRejected) {
      return _returnMethod == 'pickup'
          ? 'Picked from Hub'
          : _returnMethod == 'drop_off'
          ? 'Returned to Customer'
          : 'Confirm';
    }

    if (isReplacement && !isRejected) {
      if (_replacementAllowed) {
        return _returnMethod == 'pickup'
            ? 'Picked from Hub' // Step A: rider picks from hub
            : 'Delivered to Customer'; // Step B: rider delivers to customer
      } else {
        return _returnMethod == 'pickup'
            ? 'Picked from Customer'
            : _returnMethod == 'drop_off'
            ? 'Dropped at Hub'
            : 'Confirm';
      }
    }

    return _returnMethod == 'pickup'
        ? 'Confirm Pickup'
        : _returnMethod == 'drop_off'
        ? 'Confirm Drop-off'
        : 'Confirm';
  }

  // ── Sticky Bottom Confirm ──────────────────────────────────────────────────
  Widget _buildStickyConfirm() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        16.h + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _detailsConfirmed = !_detailsConfirmed),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    color: _detailsConfirmed
                        ? AppColors.primarycolor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: _detailsConfirmed
                          ? AppColors.primarycolor
                          : const Color(0xFFCCCCCC),
                      width: 2,
                    ),
                  ),
                  child: _detailsConfirmed
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'I confirm the above details are correct.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed:
                    (_detailsConfirmed &&
                        !_updatingStatus &&
                        _returnMethod != null)
                    ? _confirmAction
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarycolor,
                  disabledBackgroundColor: AppColors.primarycolor.withOpacity(
                    0.3,
                  ),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                            _buildConfirmLabel(),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm Action ─────────────────────────────────────────────────────────
  Future<void> _confirmAction() async {
    final method = _returnMethod;
    if (method == null) return;
    final isPickup = method == 'pickup';
    final isRejected = _display.orderStatus.toLowerCase().contains('rejected');
    final isReplacement = _display.returnType?.toLowerCase() == 'replacement';
    final isReplacementDeliveryPhase =
        isReplacement && _display.isDropped && _replacementAllowed;

    try {
      setState(() => _updatingStatus = true);

      // ── Path A: Replacement delivery phase ──────────────────────────────────
      if (isReplacementDeliveryPhase) {
        final isPickupStep =
            _returnMethod == 'pickup'; // rider picking from hub

        final result = await ReturnRepo.updateReplacementPickupStatus(
          returnId: _display.id,
          replacementPickupStatus: isPickupStep
              ? 'replacement_pick' // Step A: rider picks from hub
              : 'replacement_delivered', // Step B: rider delivers to customer
        );

        if (mounted && result['success'] == true) {
          if (isPickupStep) {
            setState(() {
              _hubPickConfirmed = true;
              _returnMethod = 'drop_off'; // ✅ switches to delivery
              _hasChanged = true;
              _detailsConfirmed = false; // ✅ unchecks confirmation
            });
            // shows snackbar...
            _fetchDetail(); // re-fetches from server
          } else {
            // final walletCredited =
            //     result['walletCredited'] ?? result['data']?['walletCredited'];
            // final walletBalance =
            //     result['walletBalance'] ?? result['data']?['walletBalance'];
            // final creditMsg = walletCredited != null
            //     ? ' ₹$walletCredited credited to wallet (Balance: ₹$walletBalance).'
            //     : '';
            setState(() {
              _hasChanged = true;
              _detailsConfirmed = false;
              _detail = _display.copyWith(
                replacementDeliveryStatus: 'delivered',
                orderStatus: 'completed',
                isDropped: true,
                pickupStatus: 'item_delivered',
              );
            });
            AppSnackbar.showSuccess(
              title: 'Delivered!',
              message: 'Replacement delivered to customer. Order complete!',
              // $creditMsg',
            );
          }
          _fetchDetail();
        } else if (mounted) {
          AppSnackbar.showError(
            title: 'Update Failed',
            message: result['message'] ?? 'Update failed.',
          );
        }
        return;
      }

      // ── Path B: Collection phase / standard refund / rejected ────────────────
      String itemStatus = isPickup ? 'picked' : 'dropped';
      String? orderStatus;
      String? pickStatus;
      String? pickupStatus;
      String? refundStatus;
      bool? updatedIsPicked;
      bool? updatedIsDropped;

      if (!isRejected) {
        if (isPickup) {
          updatedIsPicked = true;
          pickStatus = 'picked';
        } else {
          updatedIsDropped = true;
          pickStatus = 'dropped';
          pickupStatus = 'item_delivered';
        }
      }

      if (isRejected) {
        itemStatus = isPickup ? 'rejected_picked' : 'rejected_dropped';
        pickStatus = isPickup ? 'picked' : 'dropped';
        if (!isPickup) {
          refundStatus = 'Pending';
          pickupStatus = 'item_delivered';
        }
      }

      final result = await ReturnRepo.updateReturnItemStatus(
        returnId: _display.id,
        returnItemStatus: itemStatus,
        orderStatus: orderStatus,
        pickStatus: pickStatus,
        pickupStatus: pickupStatus,
        refundStatus: refundStatus,
        isPicked: updatedIsPicked,
        isDropped: updatedIsDropped,
      );

      if (mounted && result['success'] == true) {
        setState(() {
          _hasChanged = true;
          _detail = _display.copyWith(
            orderStatus: orderStatus ?? _display.orderStatus,
            returnItemStatus: itemStatus,
            isPicked: updatedIsPicked ?? _display.isPicked,
            isDropped: updatedIsDropped ?? _display.isDropped,
          );
        });
      }

      if (mounted) {
        if (result['success'] == true) {
          AppSnackbar.showSuccess(
            title: 'Success',
            message:
                'Status updated to ${itemStatus.replaceAll('_', ' ').toUpperCase()}!',
          );
          _fetchDetail();
          _hasChanged = true;
          setState(() => _detailsConfirmed = false);
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

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15.sp, color: AppColors.primarycolor),
        SizedBox(width: 6.w),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: _labelGrey,
          ),
        ),
      ],
    );
  }

  Widget _iconRow(
    IconData icon,
    String text, {
    int maxLines = 2,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.sp, color: color ?? _labelGrey),
        SizedBox(width: 7.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: color ?? Colors.grey[600]!,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _kv(
    String key,
    String value, {
    bool isStatus = false,
    String? statusText,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: TextStyle(fontSize: 13.sp, color: _labelGrey),
          ),
          SizedBox(width: 16.w),
          Flexible(
            child: isStatus && statusText != null
                ? _buildStatusPill(statusText)
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                    textAlign: TextAlign.right,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dividerLine() {
    return Divider(height: 1, color: _divider, thickness: 1);
  }

  Widget _buildStatusPill(String status) {
    final bg = _statusBg(status);
    final fg = _statusFg(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tappableButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF333333),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.25)),
          color: color.withOpacity(0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 7.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status color helpers ───────────────────────────────────────────────────
  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'refund_completed':
      case 'item_received':
      case 'received':
      case 'refunded':
      case 'returned':
      case 'return_completed':
      case 'dropped':
        return const Color(0xFFE6F9EE);
      case 'cancelled':
      case 'failed':
      case 'rejected':
      case 'not_applicable':
      case 'rejected_picked':
      case 'rejected_dropped':
        return const Color(0xFFFFEBEB);
      case 'rejected_received':
        return const Color(0xFFFFF3E0);
      case 'shipped':
      case 'out_for_delivery':
      case 'item_picked':
      case 'approved':
      case 'picked':
        return const Color(0xFFE8F0FE);
      case 'pending':
      case 'requested':
      case 'refund_requested':
      case 'refund requested':
      case 'refund_request':
      case 'refund request':
      case 'return_requested':
      case 'return requested':
      case 'return_request':
      case 'return request':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'refund_completed':
      case 'item_received':
      case 'received':
      case 'refunded':
      case 'returned':
      case 'return_completed':
      case 'dropped':
        return _green;
      case 'cancelled':
      case 'failed':
      case 'rejected':
      case 'not_applicable':
      case 'rejected_picked':
      case 'rejected_dropped':
        return _red;
      case 'rejected_received':
        return _orange;
      case 'shipped':
      case 'out_for_delivery':
      case 'item_picked':
      case 'approved':
      case 'picked':
        return _blue;
      case 'pending':
      case 'requested':
      case 'refund_requested':
      case 'refund requested':
      case 'refund_request':
      case 'refund request':
      case 'return_requested':
      case 'return requested':
      case 'return_request':
      case 'return request':
        return _orange;
      default:
        return const Color(0xFF374151);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min $ampm';
  }
}

// ── Data class ─────────────────────────────────────────────────────────────
class _TimelineStep {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool done;
  final bool active;

  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.done,
    required this.active,
  });
}
