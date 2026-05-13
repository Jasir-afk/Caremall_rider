import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/delivered_today_screen.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/order_details_screen.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/route_screen.dart';
import 'package:care_mall_rider/src/modules/profile/view/profile_screen.dart';
import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/delivery_order_model.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/return_order_model.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/return_details_screen.dart';
import 'package:care_mall_rider/src/modules/wallet/view/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isOnline = true;
  // 0: New, 1: In Transit, 2: History
  int _selectedTab = 0;
  String _userName = 'Rider';
  // ── API state ───────────
  List<DeliveryOrder> _allOrders = [];
  bool _ordersLoading = true;
  String? _ordersError;
  List<ReturnOrder> _returnOrders = [];
  bool _returnsLoading = true;
  String? _returnsError;
  // Dashboard stats from API
  double _totalCodToday = 0.0;
  int _totalDeliveredToday = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchOrders();
  }

  Future<void> _loadUserData() async {
    final name = await StorageService.getUserName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _userName = name);
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _ordersLoading = true;
      _ordersError = null;
      _returnsLoading = true;
      _returnsError = null;
    });
    // Fetch delivery orders, return orders and dashboard stats in parallel
    await Future.wait([
      OrderRepo.getDeliveryOrders()
          .then((orders) {
            if (mounted) setState(() => _allOrders = orders);
          })
          .catchError((e) {
            if (mounted) setState(() => _ordersError = e.toString());
          }),
      OrderRepo.getReturnOrders()
          .then((returns) {
            if (mounted) setState(() => _returnOrders = returns);
          })
          .catchError((e) {
            if (mounted) setState(() => _returnsError = e.toString());
          }),
      OrderRepo.getDashboardStats()
          .then((response) {
            if (mounted) {
              setState(() {
                // Determine which map holds the actual stats
                final Map<String, dynamic> stats =
                    response['stats'] ??
                    response['dashboard'] ??
                    response['data'] ??
                    response;

                debugPrint('Dashboard API Response: $stats');

                // Extract Total COD with multiple fallback keys
                _totalCodToday =
                    (stats['totalCodToday'] ??
                            stats['total_cod_today'] ??
                            stats['totalCod'] ??
                            stats['total_cod'] ??
                            stats['codToday'] ??
                            stats['cod_today'] ??
                            0.0)
                        .toDouble();

                // Extract Total Delivered with multiple fallback keys
                _totalDeliveredToday =
                    (stats['totalDeliveredToday'] ??
                    stats['total_delivered_today'] ??
                    stats['totalDelivered'] ??
                    stats['total_delivered'] ??
                    stats['deliveredToday'] ??
                    stats['delivered_today'] ??
                    stats['deliveredOrders'] ??
                    0);
              });
            }
          })
          .catchError((e) {
            debugPrint('Dashboard Fetch Error: $e');
            // Silently fail or log dashboard error
          }),
    ]);
    if (mounted) {
      setState(() {
        _ordersLoading = false;
        _returnsLoading = false;

        // --- Recalculate local stats for accuracy ---
        final now = DateTime.now();
        int localDelivered = 0;
        double localCod = 0;

        for (final o in _allOrders) {
          // Check if delivered TODAY
          if (o.orderStatus.toLowerCase() == 'delivered' &&
              o.deliveredAt != null) {
            final date = o.deliveredAt!;
            if (date.year == now.year &&
                date.month == now.month &&
                date.day == now.day) {
              localDelivered++;
              if (o.isCod) {
                localCod += o.amountToCollect;
              }
            }
          }
        }

        // Merge API stats with local calculation (take the max to be safe)
        if (localDelivered > _totalDeliveredToday) {
          _totalDeliveredToday = localDelivered;
        }
        if (localCod > _totalCodToday) {
          _totalCodToday = localCod;
        }

        // --- Merge Refund Requested Delivery Orders into Returns ---
        final refundRequestedFromDelivery = _allOrders
            .where((o) {
              final s = o.orderStatus.toLowerCase();
              return s == 'refund_requested' ||
                  s == 'refund requested' ||
                  s == 'refund_request' ||
                  s == 'refund request' ||
                  s == 'return_requested' ||
                  s == 'return requested' ||
                  s == 'return_request' ||
                  s == 'return request';
            })
            .map((o) => ReturnOrder.fromDeliveryOrder(o))
            .toList();

        // Avoid adding duplicates if they already exist in _returnOrders
        for (final r in refundRequestedFromDelivery) {
          if (!_returnOrders.any((existing) => existing.id == r.id)) {
            _returnOrders.add(r);
          }
        }
      });
    }
  }

  // Tab filters based on orderStatus
  static const _newStatuses = {
    'pending',
    'confirmed',
    'processing',
    'dispatched',
    'assigned',
    'accepted',
    'new',
  };
  static const _transitStatuses = {'shipped', 'out_for_delivery', 'picked_up'};
  static const _historyStatuses = {
    'delivered',
    'failed',
    'cancelled',
    'completed',
    'refund_completed',
  };

  List<DeliveryOrder> get _newOrders => _allOrders
      .where((o) => _newStatuses.contains(o.orderStatus.toLowerCase()))
      .toList();
  List<DeliveryOrder> get _inTransitOrders => _allOrders
      .where((o) => _transitStatuses.contains(o.orderStatus.toLowerCase()))
      .toList();
  List<DeliveryOrder> get _historyOrders => _allOrders
      .where((o) => _historyStatuses.contains(o.orderStatus.toLowerCase()))
      .toList();

  /// Today's delivered COD orders for breakdown
  List<DeliveryOrder> get _todayCodOrders {
    final now = DateTime.now();
    return _allOrders.where((o) {
      if (o.orderStatus.toLowerCase() != 'delivered' || o.deliveredAt == null) {
        return false;
      }
      final d = o.deliveredAt!;
      return d.year == now.year &&
          d.month == now.month &&
          d.day == now.day &&
          o.isCod;
    }).toList();
  }

  // ─── Dashboard Stats (Now state-based) ───────────────────────────────────
  // _selectedTab: 0=New 1=InTransit 2=Return 3=History
  bool get _isReturnTab => _selectedTab == 2;

  List<DeliveryOrder> get _currentOrders {
    switch (_selectedTab) {
      case 0:
        return _newOrders;
      case 1:
        return _inTransitOrders;
      case 3:
        return _historyOrders;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: _selectedIndex == 3
          ? const ProfileScreen()
          : _selectedIndex == 2
          ? const WalletScreen()
          : SafeArea(
              child: Column(
                children: [
                  // ─── Header ──────────────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText(
                            text: 'Hello, $_userName',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textnaturalcolor,
                          ),
                        ),
                        // Online/Offline Toggle
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: _isOnline,
                                  onChanged: (val) =>
                                      setState(() => _isOnline = val),
                                  activeThumbColor: AppColors.primarycolor,
                                  activeTrackColor: AppColors.primarycolor
                                      .withValues(alpha: 0.2),
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: Colors.grey[200],
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              AppText(
                                text: _isOnline ? 'Online' : 'Offline',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: _isOnline
                                    ? AppColors.textnaturalcolor
                                    : Colors.grey,
                              ),
                              SizedBox(width: 8.w),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_selectedIndex == 0) ...[
                    _buildDashboard(),
                    SizedBox(height: 16.h),
                    // // ─── Search Bar ──────────────────────────────────────────────────
                    // Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 16.w),
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       color: Colors.white,
                    //       borderRadius: BorderRadius.circular(8.r),
                    //       border: Border.all(color: Colors.grey[200]!),
                    //     ),
                    //     child: TextField(
                    //       decoration: InputDecoration(
                    //         hintText: 'Search Order ID',
                    //         hintStyle: TextStyle(
                    //           color: Colors.grey[400],
                    //           fontSize: 14.sp,
                    //         ),
                    //         prefixIcon: Icon(
                    //           Icons.search,
                    //           color: Colors.grey[400],
                    //         ),
                    //         border: InputBorder.none,
                    //         contentPadding: EdgeInsets.symmetric(
                    //           horizontal: 16.w,
                    //           vertical: 14.h,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: 16.h),

                    // ─── Tabs ────────────────────────────────────────────────────────────────
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
                          _buildTab('New (${_newOrders.length})', 0),
                          _buildTab(
                            'In Transit (${_inTransitOrders.length})',
                            1,
                          ),
                          _buildTab('Returns (${_returnOrders.length})', 2),
                          _buildTab('History (${_historyOrders.length})', 3),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ─── Order / Return List ──────────────────────────────────────────
                    Expanded(
                      child: _isReturnTab
                          ? _buildReturnList()
                          : _buildDeliveryList(),
                    ),
                  ] else if (_selectedIndex == 1) ...[
                    const Expanded(child: RouteScreen()),
                  ],
                ],
              ),
            ),

      // ─── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Always refresh user data (like name) when switching tabs
          // This ensures that returning from Profile -> Home shows the new name
          _loadUserData();
        },
        selectedItemColor: AppColors.primarycolor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route),
            label: 'Route',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────────────────

  Widget _buildDashboard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'COD Collected Today',
              value: '₹ ${_totalCodToday.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF6366F1),
              onTap: _showCodBreakdown,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              title: 'Delivered Today',
              value: '$_totalDeliveredToday',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeliveredTodayScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(height: 12.h),
            AppText(
              text: title,
              fontSize: 12.sp,
              color: Colors.grey[600]!,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(height: 4.h),
            AppText(
              text: value,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textnaturalcolor,
            ),
          ],
        ),
      ),
    );
  }

  void _showCodBreakdown() {
    final codOrders = _todayCodOrders;

    Get.bottomSheet(
      Container(
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: 'COD Details Today',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textnaturalcolor,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: AppText(
                    text: '₹ ${_totalCodToday.toStringAsFixed(0)}',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),
            if (codOrders.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.h),
                child: Center(
                  child: AppText(
                    text: 'No COD orders collected today.',
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 400.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: codOrders.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 24.h, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final order = codOrders[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: 'Order #${order.orderId}',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textnaturalcolor,
                            ),
                            SizedBox(height: 4.h),
                            AppText(
                              text:
                                  'Customer: ${order.shippingAddress.fullName}',
                              fontSize: 12.sp,
                              color: Colors.grey[600]!,
                            ),
                          ],
                        ),
                        AppText(
                          text: '₹ ${order.amountToCollect.toStringAsFixed(2)}',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textnaturalcolor,
                        ),
                      ],
                    );
                  },
                ),
              ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarycolor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
                child: AppText(
                  text: 'Close',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
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

  Widget _buildDeliveryList() {
    if (_ordersLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ordersError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 12.h),
            AppText(
              text: 'Could not load orders',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600]!,
            ),
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final orders = _currentOrders;
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: orders.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400.h,
                child: Center(
                  child: AppText(
                    text: 'No orders here',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500]!,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: orders.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) => _buildOrderCard(orders[index]),
            ),
    );
  }

  Widget _buildReturnList() {
    if (_returnsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_returnsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 12.h),
            AppText(
              text: 'Could not load returns',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600]!,
            ),
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_returnOrders.isEmpty) {
      return Center(
        child: AppText(
          text: 'No return orders',
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500]!,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: _returnOrders.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) => _buildReturnCard(_returnOrders[index]),
      ),
    );
  }

  Widget _buildReturnCard(ReturnOrder ret) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: ret.returnType?.toLowerCase() == 'replacement'
                              ? AppColors.warningMain.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ret.returnType?.toLowerCase() == 'replacement'
                                  ? Icons.sync
                                  : Icons.assignment_return_outlined,
                              size: 10.sp,
                              color:
                                  ret.returnType?.toLowerCase() == 'replacement'
                                  ? AppColors.warningMain
                                  : Colors.blue,
                            ),
                            SizedBox(width: 4.w),
                            AppText(
                              text:
                                  (ret.returnType?.toLowerCase() ==
                                              'replacement'
                                          ? 'replacement'
                                          : 'refund')
                                      .toUpperCase(),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color:
                                  ret.returnType?.toLowerCase() == 'replacement'
                                  ? AppColors.warningMain
                                  : Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        text: '#${ret.returnId}',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textnaturalcolor,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _statusBadgeBg(ret.orderStatus),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: AppText(
                    text: ret.orderStatus.replaceAll('_', ' ').toUpperCase(),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _statusBadgeFg(ret.orderStatus),
                  ),
                ),
              ],
            ),
            if (ret.customerName != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14.sp,
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: AppText(
                      text: ret.customerName!,
                      fontSize: 13.sp,
                      color: AppColors.textnaturalcolor,
                    ),
                  ),
                ],
              ),
            ],
            if (ret.address != null) ...[
              SizedBox(height: 4.h),
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
                      text: ret.address!,
                      fontSize: 12.sp,
                      color: Colors.grey[600]!,
                    ),
                  ),
                ],
              ),
            ],
            if (ret.reason != null) ...[
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14.sp,
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: AppText(
                      text: 'Reason: ${ret.reason}',
                      fontSize: 12.sp,
                      color: Colors.grey[600]!,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: '₹ ${ret.totalAmount.toStringAsFixed(0)}',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textnaturalcolor,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: SizedBox(
                    height: 36.h,
                    child: AppButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReturnDetailsScreen(returnOrder: ret),
                          ),
                        );
                        if (result == true && mounted) {
                          _fetchOrders();
                        }
                      },
                      btncolor: AppColors.primarycolor,
                      borderRadius: 6.r,
                      buttonStyle: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          AppColors.primarycolor,
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                      child: AppText(
                        text: ret.returnType?.toLowerCase() == 'replacement'
                            ? 'Start Replacement'
                            : 'Start Refund',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    final bool isCod = order.isCod;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Order ID + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppText(
                    text: 'Order ID : ${order.orderId}',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textnaturalcolor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _statusBadgeBg(order.orderStatus),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: AppText(
                    text: order.orderStatus.replaceAll('_', ' ').toUpperCase(),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _statusBadgeFg(order.orderStatus),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Pickup section
            if (order.dispatch?.destination != null &&
                order.orderStatus.toLowerCase() != 'delivered') ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 14.sp,
                    color: const Color(0xFF6366F1),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: 'PICKUP FROM',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6366F1),
                        ),
                        SizedBox(height: 2.h),
                        AppText(
                          text: order.dispatch!.destination,
                          fontSize: 12.sp,
                          color: AppColors.textnaturalcolor,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],

            // Delivery section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.person_pin_circle_outlined,
                  size: 14.sp,
                  color: AppColors.primarycolor,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: 'DELIVER TO',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primarycolor,
                      ),
                      SizedBox(height: 2.h),
                      AppText(
                        text: order.fullAddress,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textnaturalcolor,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Bottom Row: Payment + Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCod) ...[
                      AppText(
                        text: 'Cash on Delivery',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textDefaultSecondarycolor,
                      ),
                      SizedBox(height: 2.h),
                      AppText(
                        text: '₹ ${order.amountToCollect.toStringAsFixed(0)}',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textnaturalcolor,
                      ),
                    ] else
                      AppText(
                        text: 'Pre Paid',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPositiveSecondarycolor,
                      ),
                  ],
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: order.orderStatus.toLowerCase() == 'delivered'
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailsScreen(order: order),
                              ),
                            );
                          },
                          child: Container(
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EE),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF1E7E4C),
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                AppText(
                                  text: 'Paid',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E7E4C),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 40.h,
                          child: AppButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OrderDetailsScreen(order: order),
                                ),
                              );
                              if (result == true && mounted) {
                                _fetchOrders();
                              }
                            },
                            btncolor: AppColors.primarycolor,
                            borderRadius: 6.r,
                            buttonStyle: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                AppColors.primarycolor,
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                            ),
                            child: AppText(
                              text: _selectedTab == 0
                                  ? 'Start Delivery'
                                  : 'View Details',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
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
      case 'refund_requested':
      case 'refund requested':
      case 'refund_request':
      case 'refund request':
      case 'return_requested':
      case 'return requested':
      case 'return_request':
      case 'return request':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF374151);
    }
  }
}
