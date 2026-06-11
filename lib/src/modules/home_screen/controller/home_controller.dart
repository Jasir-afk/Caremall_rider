import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/src/modules/auth/controller/auth_repo.dart';
import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/delivery_order_model.dart';
import 'package:care_mall_rider/src/modules/return/controller/return_repo.dart';
import 'package:care_mall_rider/src/modules/return/model/return_order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// HomeController manages all state for the HomeScreen
/// Handles orders, returns, dashboard stats, loading states, and UI interactions
class HomeController extends GetxController {
  // Navigation state
  final selectedIndex = 0.obs;
  final isOnline = true.obs;

  // Tab state: 0=New, 1=In Transit, 2=Returns, 3=History
  final selectedTab = 0.obs;

  // User data
  final userName = 'Rider'.obs;
  final userAvatar = Rxn<String>();

  // API state - Delivery Orders
  final allOrders = <DeliveryOrder>[].obs;
  final allOrdersForCounts = <DeliveryOrder>[].obs;
  final ordersLoading = true.obs;
  final ordersError = Rxn<String>();

  // API state - Return Orders
  final returnOrders = <ReturnOrder>[].obs;
  final returnsLoading = true.obs;
  final returnsError = Rxn<String>();

  // Dashboard stats
  final totalCodToday = 0.0.obs;
  final totalDeliveredToday = 0.obs;

  // Pagination state
  final currentPage = 1.obs;
  final pageSize = 10;
  final hasMoreOrders = true.obs;
  final hasMoreReturns = true.obs;
  final loadingMore = false.obs;

  // Client-side visible count per tab
  static const int pageLimit = 10;
  final visibleNewCount = pageLimit.obs;
  final visibleHistoryCount = pageLimit.obs;
  final visibleReturnCount = pageLimit.obs;

  // Scroll state
  final hasScrolledBeyondFirstPage = false.obs;
  final deliveryScrollController = ScrollController();
  final historyScrollController = ScrollController();
  final returnScrollController = ScrollController();

  // Search state
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  // Tab status filters
  static const newStatuses = {
    'pending',
    'confirmed',
    'processing',
    'dispatched',
    'assigned',
    'accepted',
    'new',
  };

  static const transitStatuses = {
    'shipped',
    'shipping',
    'out_for_delivery',
    'picked_up',
    'undelivered',
  };

  static const historyStatuses = {
    'delivered',
    'failed',
    'cancelled',
    'completed',
    'refund_completed',
    'returned',
    'refunded',
    'return_completed',
  };

  void onInit() {
    super.onInit();
    loadUserData();
    fetchOnlineStatus();
    fetchOrders();
    setupScrollListeners();
  }

  void onClose() {
    deliveryScrollController.dispose();
    historyScrollController.dispose();
    returnScrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// Load user data from storage
  Future<void> loadUserData() async {
    final name = await StorageService.getUserName();
    final avatar = await StorageService.getUserAvatar();
    if (name != null && name.isNotEmpty) userName.value = name;
    if (avatar != null) userAvatar.value = avatar;
  }

  /// Fetch online status from API
  Future<void> fetchOnlineStatus() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        // Try to get from local storage if no token
        final localStatus = await StorageService.getOnlineStatus();
        if (localStatus != null) {
          isOnline.value = localStatus;
        }
        return;
      }

      final response = await AuthRepo.getOnlineStatus(token: token);
      if (response['success'] == true) {
        final data = response['data'];
        // Try multiple possible response structures
        final bool? apiStatus =
            data?['isOnline'] ??
            data?['is_online'] ??
            data?['online'] ??
            data?['status'];
        if (apiStatus != null) {
          isOnline.value = apiStatus;
          // Save to local storage
          await StorageService.saveOnlineStatus(apiStatus);
        }
      } else {
        // Fallback to local storage on API failure
        final localStatus = await StorageService.getOnlineStatus();
        if (localStatus != null) {
          isOnline.value = localStatus;
        }
      }
    } catch (e) {
      debugPrint('Error fetching online status: $e');
      // Fallback to local storage on error
      final localStatus = await StorageService.getOnlineStatus();
      if (localStatus != null) {
        isOnline.value = localStatus;
      }
    }
  }

  /// Setup scroll listeners for pagination
  void setupScrollListeners() {
    deliveryScrollController.addListener(() {
      if (deliveryScrollController.position.pixels > 200) {
        hasScrolledBeyondFirstPage.value = true;
      }
    });

    historyScrollController.addListener(() {
      if (historyScrollController.position.pixels > 200) {
        hasScrolledBeyondFirstPage.value = true;
      }
    });

    returnScrollController.addListener(() {
      if (returnScrollController.position.pixels > 200) {
        hasScrolledBeyondFirstPage.value = true;
      }
    });
  }

  /// Fetch orders, returns, and dashboard stats
  Future<void> fetchOrders({bool loadMore = false}) async {
    // Check KYC status once and cache result
    final kycStatus = await StorageService.getKycStatus();
    final kycStatusLower = kycStatus.toLowerCase();

    if (kycStatusLower != 'approved' && kycStatusLower != 'verified') {
      ordersLoading.value = false;
      returnsLoading.value = false;
      ordersError.value =
          'KYC verification required. Please complete your KYC verification to receive orders.';
      returnsError.value =
          'KYC verification required. Please complete your KYC verification to receive orders.';
      allOrders.clear();
      returnOrders.clear();
      return;
    }

    if (loadMore) {
      loadingMore.value = true;
    } else {
      ordersLoading.value = true;
      ordersError.value = null;
      returnsLoading.value = true;
      returnsError.value = null;
      currentPage.value = 1;
      hasMoreOrders.value = true;
      hasMoreReturns.value = true;
    }

    // Fetch data in parallel
    await Future.wait([
      _fetchDeliveryOrders(loadMore),
      _fetchDashboardStats(),
      _fetchReturnOrders(loadMore),
    ]);

    ordersLoading.value = false;
    returnsLoading.value = false;
    loadingMore.value = false;

    _calculateLocalStats();
    _mergeRefundRequestedOrders();
  }

  Future<void> _fetchDeliveryOrders(bool loadMore) async {
    try {
      final orders = await OrderRepo.getDeliveryOrders(
        page: currentPage.value,
        limit: pageSize,
      );

      // Check for new orders and notify rider
      if (!loadMore) {
        await checkForNewOrders(orders);
      }

      if (loadMore) {
        allOrders.addAll(orders);
      } else {
        allOrders.assignAll(orders);
      }
      hasMoreOrders.value = orders.length >= pageSize;
    } catch (e) {
      ordersError.value = e.toString();
    }
  }

  /// Check for newly assigned orders and show notification
  Future<void> checkForNewOrders(
    List<DeliveryOrder> newOrders, {
    List<DeliveryOrder>? existingOrders,
  }) async {
    // Get existing order IDs from storage (not from current state)
    final lastKnownOrderIds = await StorageService.getLastKnownOrderIds();
    final existingOrderIdsSet = lastKnownOrderIds.toSet();

    // Find orders that are in "New" status and weren't in the previous list
    final newlyAssignedOrders = newOrders.where((order) {
      final status = order.orderStatus.toLowerCase();
      final isNewOrder = newStatuses.contains(status);
      final isPreviouslyUnknown = !existingOrderIdsSet.contains(order.id);
      return isNewOrder && isPreviouslyUnknown;
    }).toList();

    // Show notification if there are new orders
    if (newlyAssignedOrders.isNotEmpty) {
      final count = newlyAssignedOrders.length;
      Get.bottomSheet(
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Icon with animation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'New Order${count > 1 ? 's' : ''} Assigned!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    count == 1
                        ? 'You have a new delivery order:\n${newlyAssignedOrders.first.orderId}'
                        : 'You have $count new delivery orders\nready for delivery',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Got It',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
      );

      // Save updated order IDs to storage after showing notification
      final allCurrentOrderIds = newOrders.map((o) => o.id).toList();
      await StorageService.saveLastKnownOrderIds(allCurrentOrderIds);
    } else {
      // Even if no new orders, update storage with current order IDs
      // to keep the stored list in sync
      final allCurrentOrderIds = newOrders.map((o) => o.id).toList();
      await StorageService.saveLastKnownOrderIds(allCurrentOrderIds);
    }
  }

  Future<void> _fetchReturnOrders(bool loadMore) async {
    try {
      final returns = await ReturnRepo.getReturnOrders(
        page: currentPage.value,
        limit: pageSize,
      );
      if (loadMore) {
        returnOrders.addAll(returns);
      } else {
        returnOrders.assignAll(returns);
      }
      hasMoreReturns.value = returns.length >= pageSize;
    } catch (e) {
      returnsError.value = e.toString();
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final response = await OrderRepo.getDashboardStats();
      final Map<String, dynamic> stats =
          response['stats'] ??
          response['dashboard'] ??
          response['data'] ??
          response;

      // Extract Total COD with multiple fallback keys
      totalCodToday.value =
          (stats['totalCodToday'] ??
                  stats['total_cod_today'] ??
                  stats['totalCod'] ??
                  stats['total_cod'] ??
                  stats['codToday'] ??
                  stats['cod_today'] ??
                  0.0)
              .toDouble();

      // Extract Total Delivered with multiple fallback keys
      totalDeliveredToday.value =
          stats['totalDeliveredToday'] ??
          stats['total_delivered_today'] ??
          stats['totalDelivered'] ??
          stats['total_delivered'] ??
          stats['deliveredToday'] ??
          stats['delivered_today'] ??
          stats['deliveredOrders'] ??
          0;
    } catch (e) {
      debugPrint('Dashboard Fetch Error: $e');
    }
  }

  void _calculateLocalStats() {
    final ordersForCalculations = allOrdersForCounts.isNotEmpty
        ? allOrdersForCounts
        : allOrders;
    final now = DateTime.now();
    int localDelivered = 0;
    double localCod = 0;

    for (final o in ordersForCalculations) {
      if (o.orderStatus.toLowerCase() == 'delivered' && o.deliveredAt != null) {
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

    // Merge API stats with local calculation
    if (localDelivered > totalDeliveredToday.value) {
      totalDeliveredToday.value = localDelivered;
    }
    if (localCod > totalCodToday.value) {
      totalCodToday.value = localCod;
    }
  }

  void _mergeRefundRequestedOrders() {
    final ordersForCalculations = allOrdersForCounts.isNotEmpty
        ? allOrdersForCounts
        : allOrders;
    final refundRequestedFromDelivery = ordersForCalculations
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

    // Avoid adding duplicates
    for (final r in refundRequestedFromDelivery) {
      if (!returnOrders.any((existing) => existing.id == r.id)) {
        returnOrders.add(r);
      }
    }
  }

  // Getters for filtered orders
  List<DeliveryOrder> get baseOrders =>
      allOrdersForCounts.isNotEmpty ? allOrdersForCounts : allOrders;

  List<DeliveryOrder> get newOrders => baseOrders
      .where((o) => newStatuses.contains(o.orderStatus.toLowerCase()))
      .toList();

  List<DeliveryOrder> get inTransitOrders => baseOrders
      .where(
        (o) =>
            transitStatuses.contains(o.orderStatus.toLowerCase()) &&
            !(o.undeliveredWarehouseDrop && o.isFromWarehouse),
      )
      .toList();

  List<DeliveryOrder> get historyOrders => baseOrders
      .where((o) => historyStatuses.contains(o.orderStatus.toLowerCase()))
      .toList();

  List<ReturnOrder> get activeReturnOrders => returnOrders.where((o) {
    final status = o.orderStatus.toLowerCase();
    final itemStatus = (o.returnItemStatus?.toLowerCase() ?? '').replaceAll(
      ' ',
      '_',
    );
    final replStatus = o.replacementDeliveryStatus?.toLowerCase();
    final isReplacement = o.returnType?.toLowerCase() == 'replacement';

    if (status == 'rejected' && itemStatus != 'rejected_dropped') return true;
    if (itemStatus == 'rejected_dropped') return false;
    if (historyStatuses.contains(status)) return false;
    if (isReplacement &&
        (replStatus == 'completed' || replStatus == 'delivered'))
      return false;

    return true;
  }).toList();

  List<ReturnOrder> get historyReturnOrders => returnOrders.where((o) {
    final status = o.orderStatus.toLowerCase();
    final itemStatus = (o.returnItemStatus?.toLowerCase() ?? '').replaceAll(
      ' ',
      '_',
    );
    final replStatus = o.replacementDeliveryStatus?.toLowerCase();
    final isReplacement = o.returnType?.toLowerCase() == 'replacement';

    if (status == 'rejected' && itemStatus == 'rejected_dropped') return true;
    if (status == 'rejected') return false;
    if (historyStatuses.contains(status)) return true;
    if (itemStatus == 'rejected_dropped') return true;
    if (isReplacement &&
        (replStatus == 'completed' || replStatus == 'delivered'))
      return true;

    return false;
  }).toList();

  List<DeliveryOrder> get todayCodOrders {
    final now = DateTime.now();
    return baseOrders.where((o) {
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

  // Filter orders based on search query
  List<DeliveryOrder> filterDeliveryOrders(List<DeliveryOrder> orders) {
    if (searchQuery.value.isEmpty) return orders;
    final query = searchQuery.value.toLowerCase();
    return orders.where((order) {
      return order.orderId.toLowerCase().contains(query) ||
          order.shippingAddress.fullName.toLowerCase().contains(query) ||
          order.shippingAddress.phone.toLowerCase().contains(query);
    }).toList();
  }

  List<ReturnOrder> filterReturnOrders(List<ReturnOrder> orders) {
    if (searchQuery.value.isEmpty) return orders;
    final query = searchQuery.value.toLowerCase();
    return orders.where((order) {
      return order.returnId.toLowerCase().contains(query) ||
          (order.customerName?.toLowerCase().contains(query) ?? false) ||
          (order.customerPhone?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // UI Actions
  void changeTabIndex(int index) {
    selectedTab.value = index;
  }

  void changeBottomNavIndex(int index) {
    selectedIndex.value = index;
  }

  Future<void> toggleOnlineStatus(bool value) async {
    isOnline.value = value;
    // Save to local storage immediately for UI responsiveness
    await StorageService.saveOnlineStatus(value);

    // Try to sync with API
    try {
      final token = await StorageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        final response = await AuthRepo.toggleOnlineStatus(
          isOnline: value,
          token: token,
        );
        if (response['success'] != true) {
          debugPrint(
            'Failed to update online status on server: ${response['message']}',
          );
          // Revert to local storage value on API failure
          isOnline.value = value;
        }
      }
    } catch (e) {
      debugPrint('Error toggling online status: $e');
      // Keep local value even if API fails
    }
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value;
  }

  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
  }

  void loadMoreOrders() {
    if (!loadingMore.value && hasMoreOrders.value) {
      currentPage.value++;
      fetchOrders(loadMore: true);
    }
  }

  void refreshOrders() {
    fetchOnlineStatus();
    fetchOrders();
  }
}
