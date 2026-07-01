import 'dart:async';

import 'package:care_mall_rider/app/app_buttons/app_buttons.dart';
import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:care_mall_rider/src/modules/home_screen/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/delivered_today_screen.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/order_details_screen.dart';
import 'package:care_mall_rider/src/modules/home_screen/view/route_screen.dart';
import 'package:care_mall_rider/src/modules/profile/view/profile_screen.dart';
import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';
import 'package:care_mall_rider/src/modules/home_screen/model/delivery_order_model.dart';
import 'package:care_mall_rider/src/modules/return/controller/return_repo.dart';
import 'package:care_mall_rider/src/modules/return/model/return_order_model.dart';
import 'package:care_mall_rider/src/modules/return/view/return_details_screen.dart';
import 'package:care_mall_rider/src/modules/wallet/view/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isOnline = true;
  // 0: New, 1: In Transit, 2: History
  int _selectedTab = 0;
  String _userName = 'Rider';
  String? _userAvatar;
  // ── API state ───────────
  List<DeliveryOrder> _allOrders = [];
  List<DeliveryOrder> _allOrdersForCounts = [];
  bool _ordersLoading = true;
  String? _ordersError;
  List<ReturnOrder> _returnOrders = [];
  bool _returnsLoading = true;
  String? _returnsError;
  // Dashboard stats from API
  double _totalCodToday = 0.0;
  int _totalDeliveredToday = 0;
  // Pagination state
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreOrders = true;
  bool _hasMoreReturns = true;
  bool _loadingMore = false;
  // Client-side visible count per tab - increases dynamically with more orders
  static const int _pageLimit = 10;
  int _visibleNewCount = _pageLimit;
  int _visibleHistoryCount = _pageLimit;
  int _visibleReturnCount = _pageLimit;
  Timer? _pollingTimer;
  bool _isSilentPolling = false;
  bool _isShowingNotificationBottomSheet = false;
  // Scroll controllers
  final ScrollController _deliveryScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  final ScrollController _returnScrollController = ScrollController();
  // Scroll state
  bool _hasScrolledBeyondFirstPage = false;
  // Search state
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Incoming-orders refresh — polls every 30 s and silently updates only
  // new/incoming order counts and info. Does NOT refresh returns or stats.

  // Filter orders based on search query
  List<DeliveryOrder> _filterDeliveryOrders(List<DeliveryOrder> orders) {
    if (_searchQuery.isEmpty) return orders;
    final query = _searchQuery.toLowerCase();
    return orders.where((order) {
      return order.orderId.toLowerCase().contains(query) ||
          order.shippingAddress.fullName.toLowerCase().contains(query) ||
          order.shippingAddress.phone.toLowerCase().contains(query);
    }).toList();
  }

  // Filter return orders based on search query
  List<ReturnOrder> _filterReturnOrders(List<ReturnOrder> orders) {
    if (_searchQuery.isEmpty) return orders;
    final query = _searchQuery.toLowerCase();
    return orders.where((order) {
      return order.returnId.toLowerCase().contains(query) ||
          (order.customerName?.toLowerCase().contains(query) ?? false) ||
          (order.customerPhone?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchOrders(); // full initial load (orders + returns + stats + bottom sheet)
    _setupScrollListeners();
    _startIncomingPolling(); // auto-refresh incoming orders
  }

  /// Polls every 30 seconds to check for new assignments silently.
  /// If a new assignment is found, the bottom sheet is shown and a full
  /// auto-refresh is triggered once to update all lists, counts, and stats.
  void _startIncomingPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isSilentPolling || !mounted) return;
      _isSilentPolling = true;
      try {
        await _silentRefreshIncoming();
      } finally {
        _isSilentPolling = false;
      }
    });
  }

  /// Silently fetches page-1 of delivery and return orders to check for new ones.
  /// If new details are detected, triggers _fetchOrders() to auto-refresh the UI once.
  Future<void> _silentRefreshIncoming() async {
    try {
      if (!Get.isRegistered<HomeController>()) return;
      final controller = Get.find<HomeController>();

      int newOrdersCount = 0;
      int newReturnsCount = 0;

      // 1. Silent fetch and check delivery orders (skip notification)
      final orders = await OrderRepo.getDeliveryOrders(
        page: 1,
        limit: _pageSize,
      );
      if (mounted) {
        newOrdersCount = await controller.checkForNewOrders(
          orders,
          existingOrders: _allOrders,
          skipNotification: true,
        );
      }

      // 2. Silent fetch and check return orders (skip notification)
      final returns = await ReturnRepo.getReturnOrders(
        page: 1,
        limit: _pageSize,
      );
      final detailedReturns = await Future.wait(
        returns.map((r) async {
          try {
            return await ReturnRepo.getReturnDetail(r.id);
          } catch (_) {
            return r;
          }
        }),
      );
      if (mounted) {
        newReturnsCount = await controller.checkForNewReturns(
          detailedReturns,
          skipNotification: true,
        );
      }

      // 3. If any new details arrived, show single combined bottomsheet and auto-refresh
      if ((newOrdersCount > 0 || newReturnsCount > 0) && mounted) {
        debugPrint(
          'New incoming details detected! Showing combined notification.',
        );
        await _showCombinedNewOrdersBottomSheet(
          newOrdersCount,
          newReturnsCount,
        );
        // Use silent=true so the UI updates without loading spinners
        await _fetchOrders(silent: true);
      }
    } catch (e) {
      debugPrint('Incoming orders silent check error: $e');
    }
  }

  /// Show a single combined bottomsheet for new orders and returns
  Future<void> _showCombinedNewOrdersBottomSheet(
    int newOrdersCount,
    int newReturnsCount,
  ) async {
    if (_isShowingNotificationBottomSheet || Get.isBottomSheetOpen == true) {
      debugPrint(
        'A bottom sheet is already open or opening. Skipping combined notification.',
      );
      return;
    }
    _isShowingNotificationBottomSheet = true;

    final totalNew = newOrdersCount + newReturnsCount;
    final message = newOrdersCount > 0 && newReturnsCount > 0
        ? 'You have $newOrdersCount new delivery order${newOrdersCount > 1 ? 's' : ''} and $newReturnsCount new return${newReturnsCount > 1 ? 's' : ''} assigned'
        : newOrdersCount > 0
        ? 'You have $newOrdersCount new delivery order${newOrdersCount > 1 ? 's' : ''} assigned'
        : 'You have $newReturnsCount new return${newReturnsCount > 1 ? 's' : ''} assigned';

    await Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: newReturnsCount > 0
                ? [
                    const Color(0xFFFF7878),
                    AppColors.primarycolor.withValues(alpha: 0.8),
                  ]
                : [const Color(0xFF10B981), const Color(0xFF059669)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  child: Icon(
                    newReturnsCount > 0
                        ? Icons.assignment_return_rounded
                        : Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'New Assignment${totalNew > 1 ? 's' : ''}!',
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
                  message,
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
                    onPressed: () {
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: newReturnsCount > 0
                          ? AppColors.primarycolor
                          : const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.black,
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
    _isShowingNotificationBottomSheet = false;
  }

  void _setupScrollListeners() {
    _deliveryScrollController.addListener(() {
      if (_deliveryScrollController.position.pixels > 200) {
        if (mounted && !_hasScrolledBeyondFirstPage) {
          setState(() => _hasScrolledBeyondFirstPage = true);
        }
      }
    });

    _historyScrollController.addListener(() {
      if (_historyScrollController.position.pixels > 200) {
        if (mounted && !_hasScrolledBeyondFirstPage) {
          setState(() => _hasScrolledBeyondFirstPage = true);
        }
      }
    });

    _returnScrollController.addListener(() {
      if (_returnScrollController.position.pixels > 200) {
        if (mounted && !_hasScrolledBeyondFirstPage) {
          setState(() => _hasScrolledBeyondFirstPage = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _deliveryScrollController.dispose();
    _historyScrollController.dispose();
    _returnScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final name = await StorageService.getUserName();
    final avatar = await StorageService.getUserAvatar();
    final savedOnlineStatus = await StorageService.getOnlineStatus();
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        _userAvatar = avatar;
        // Load saved online status, default to true if not set
        _isOnline = savedOnlineStatus ?? true;
      });
    }
  }

  Future<void> _fetchOrders({
    bool loadMore = false,
    bool silent = false,
  }) async {
    if (loadMore) {
      setState(() => _loadingMore = true);
    } else if (silent) {
      // Silent auto-refresh: reset page but skip loading spinners so screen doesn't flash
      _currentPage = 1;
    } else {
      // Show loading spinners only on manual / initial fetches
      setState(() {
        _ordersLoading = true;
        _ordersError = null;
        _returnsLoading = true;
        _returnsError = null;
        _currentPage = 1;
        _hasMoreOrders = true;
        _hasMoreReturns = true;
      });
    }
    // Fetch delivery orders, return orders and dashboard stats in parallel
    await Future.wait([
      OrderRepo.getDeliveryOrders(page: _currentPage, limit: _pageSize)
          .then((orders) {
            if (mounted) {
              // Check for new orders and notify rider using HomeController
              // Skip notification on silent refresh — it was already shown by _silentRefreshIncoming
              if (!loadMore && !silent && Get.isRegistered<HomeController>()) {
                final controller = Get.find<HomeController>();
                controller.checkForNewOrders(
                  orders,
                  existingOrders: _allOrders,
                );
              }

              setState(() {
                if (loadMore) {
                  _allOrders.addAll(orders);
                } else {
                  _allOrders = orders;
                  _allOrdersForCounts = orders; // Use same orders for counts
                }
                _hasMoreOrders = orders.length >= _pageSize;
              });
            }
          })
          .catchError((e) {
            if (mounted) setState(() => _ordersError = e.toString());
          }),
      ReturnRepo.getReturnOrders(
            page: _currentPage,
            limit: _pageSize, // Use pagination for return orders
          )
          .then((returns) async {
            debugPrint('=== RETURN ORDERS FETCH START ===');
            debugPrint('Fetched ${returns.length} return orders');

            // Fetch details for each return order in parallel to guarantee complete fields
            final detailedReturns = await Future.wait(
              returns.map((r) async {
                try {
                  return await ReturnRepo.getReturnDetail(r.id);
                } catch (e) {
                  debugPrint('Failed to fetch detail for return ${r.id}: $e');
                  return r;
                }
              }),
            );

            // Check for new returns and show bottom sheet using HomeController
            // Skip notification on silent refresh — it was already shown by _silentRefreshIncoming
            if (!loadMore && !silent && Get.isRegistered<HomeController>()) {
              final controller = Get.find<HomeController>();
              await controller.checkForNewReturns(detailedReturns);
            }

            debugPrint('=== RETURN ORDERS FETCH END ===');
            if (mounted) {
              setState(() {
                if (loadMore) {
                  _returnOrders.addAll(detailedReturns);
                } else {
                  _returnOrders = detailedReturns;
                }
                _hasMoreReturns = detailedReturns.length >= _pageSize;
              });
            }
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
        _loadingMore = false;

        final ordersForCalculations = _allOrdersForCounts.isNotEmpty
            ? _allOrdersForCounts
            : _allOrders;

        // --- Recalculate local stats for accuracy ---
        final now = DateTime.now();
        int localDelivered = 0;
        double localCod = 0;

        for (final o in ordersForCalculations) {
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

        // Avoid adding duplicates if they already exist in _returnOrders
        for (final r in refundRequestedFromDelivery) {
          if (!_returnOrders.any((existing) => existing.id == r.id)) {
            _returnOrders.add(r);
          }
        }

        // --- Automatically increase visible counts to show all orders ---
        // This ensures old orders remain visible and new orders are shown without hiding old ones
        _visibleNewCount = _newOrders.length + _inTransitOrders.length;
        _visibleHistoryCount =
            _historyOrders.length + _historyReturnOrders.length;
        _visibleReturnCount = _activeReturnOrders.length;
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
  static const _transitStatuses = {
    'shipped',
    'shipping',
    'out_for_delivery',
    'picked_up',
    'undelivered',
  };
  static const _historyStatuses = {
    'delivered',
    'failed',
    'cancelled',
    'completed',
    'refund_completed',
    'returned',
    'refunded',
    'return_completed',
  };

  List<DeliveryOrder> get _baseOrders {
    final list = _allOrdersForCounts.isNotEmpty
        ? _allOrdersForCounts
        : _allOrders;
    final sortedList = List<DeliveryOrder>.from(list);
    sortedList.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return b.id.compareTo(a.id);
    });
    return sortedList;
  }

  List<DeliveryOrder> get _newOrders => _baseOrders
      .where((o) => _newStatuses.contains(o.orderStatus.toLowerCase()))
      .toList();
  List<DeliveryOrder> get _inTransitOrders => _baseOrders
      .where(
        (o) =>
            _transitStatuses.contains(o.orderStatus.toLowerCase()) &&
            !(o.undeliveredWarehouseDrop && o.isFromWarehouse),
      )
      .toList();
  List<DeliveryOrder> get _historyOrders => _baseOrders
      .where((o) => _historyStatuses.contains(o.orderStatus.toLowerCase()))
      .toList();

  // For counts, use same source (no longer separate – kept for tab badge usage)
  List<DeliveryOrder> get _newOrdersForCount => _newOrders;
  List<DeliveryOrder> get _inTransitOrdersForCount => _inTransitOrders;
  List<DeliveryOrder> get _historyOrdersForCount => _historyOrders;

  List<ReturnOrder> get _activeReturnOrders {
    final list = _returnOrders.where((o) {
      final status = o.orderStatus.toLowerCase();
      final itemStatus = (o.returnItemStatus?.toLowerCase() ?? '').replaceAll(
        ' ',
        '_',
      );
      final replStatus = o.replacementDeliveryStatus?.toLowerCase();
      final refundStatus = o.refundStatus?.toLowerCase();
      final isReplacement = o.returnType?.toLowerCase() == 'replacement';
      final isFromWarehouse = o.isFromWarehouse;

      // ── Terminal item-level check (highest priority) ──────────────
      // refund - rejected_dropped: rider is done → goes to History
      if (!isReplacement && itemStatus == 'rejected_dropped') return false;

      // replacement - rejected_dropped: rider is done → goes to History
      if (isReplacement && itemStatus == 'rejected_dropped') return false;

      // replacement - completed: rider is done → goes to History
      if (isReplacement && replStatus == 'completed') return false;

      // replacement - delivered: rider is done → goes to History
      if (isReplacement && replStatus == 'delivered') return false;

      // refund - completed: rider is done → goes to History
      if (!isReplacement && status == 'refund_completed') return false;

      // ── Warehouse/Delivery Hub specific handling ─────────────────
      // Warehouse-assigned: order status itself is reject_dropped → history
      if (isFromWarehouse && status == 'reject_dropped') return false;

      // Warehouse replacement dropped: stay active until replacement delivery is also completed
      if (isFromWarehouse && o.isDropped && isReplacement) {
        if (replStatus == 'completed' || replStatus == 'delivered') {
          return false;
        }
        // fall through → remains active (phase 2 still needed)
      }

      // ── Order-level status checks ─────────────────────────────────
      // Rejected but not yet refunded → still active
      if (status == 'rejected') {
        // If refund is completed, rider is done → goes to History
        if (refundStatus == 'completed' ||
            refundStatus == 'refunded' ||
            refundStatus == 'success' ||
            refundStatus == 'processed' ||
            refundStatus == 'done') {
          return false;
        }
        return true;
      }

      if (_historyStatuses.contains(status)) {
        if (isReplacement) {
          // For replacement orders, move to history if:
          // 1. Order status is completed/delivered, OR
          // 2. Replacement delivery status is completed/delivered
          if (status == 'completed' || status == 'delivered') {
            return false; // Order itself is completed → goes to history
          }
          return !(replStatus == 'completed' || replStatus == 'delivered');
        }
        return false;
      }

      return true;
    }).toList();

    list.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return b.id.compareTo(a.id);
    });
    return list;
  }

  List<ReturnOrder> get _historyReturnOrders {
    final list = _returnOrders.where((o) {
      final status = o.orderStatus.toLowerCase();
      final itemStatus = (o.returnItemStatus?.toLowerCase() ?? '').replaceAll(
        ' ',
        '_',
      );
      final replStatus = o.replacementDeliveryStatus?.toLowerCase();
      final refundStatus = o.refundStatus?.toLowerCase();
      final isReplacement = o.returnType?.toLowerCase() == 'replacement';
      final isFromWarehouse = o.isFromWarehouse;

      // ── Only completed / rider-done orders belong in History ──────

      // refund - rejected_dropped: rider done → History
      if (!isReplacement && itemStatus == 'rejected_dropped') return true;

      // replacement - rejected_dropped: rider done → History
      if (isReplacement && itemStatus == 'rejected_dropped') return true;

      // replacement - completed: rider done → History
      if (isReplacement && replStatus == 'completed') return true;

      // replacement - delivered: rider done → History
      if (isReplacement && replStatus == 'delivered') return true;

      // refund - completed: rider done → History
      if (!isReplacement && status == 'refund_completed') return true;

      // ── Warehouse/Delivery Hub specific handling ─────────────────
      // Warehouse-assigned: order status itself is reject_dropped → history
      if (isFromWarehouse && status == 'reject_dropped') return true;

      // Warehouse replacement dropped: only in history when replacement delivery is completed
      if (isFromWarehouse && o.isDropped && isReplacement) {
        if (replStatus == 'completed' || replStatus == 'delivered') {
          return true;
        }
        // fall through → not in history yet (phase 2 still needed)
      }

      // Rejected but refunded → rider done → History
      if (status == 'rejected') {
        if (refundStatus == 'completed' ||
            refundStatus == 'refunded' ||
            refundStatus == 'success' ||
            refundStatus == 'processed' ||
            refundStatus == 'done') {
          return true;
        }
        // Rejected but not yet refunded → still active (not in History)
        return false;
      }

      // Order-level terminal completed statuses
      if (_historyStatuses.contains(status)) {
        if (isReplacement) {
          // For replacement orders, move to history if:
          // 1. Order status is completed/delivered, OR
          // 2. Replacement delivery status is completed/delivered
          if (status == 'completed' || status == 'delivered') {
            return true; // Order itself is completed → goes to history
          }
          return replStatus == 'completed' || replStatus == 'delivered';
        }
        return true;
      }

      return false;
    }).toList();

    list.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return b.id.compareTo(a.id);
    });
    return list;
  }

  /// Today's delivered COD orders for breakdown
  List<DeliveryOrder> get _todayCodOrders {
    final now = DateTime.now();
    return _baseOrders.where((o) {
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

  Future<bool> _onWillPop() async {
    if (_isOnline) {
      final result = await Get.dialog<bool>(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                AppText(
                  text: 'Go Offline?',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textnaturalcolor,
                ),
                SizedBox(height: 12.h),
                AppText(
                  text:
                      'You are currently online. Do you want to go offline before closing the app?',
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: AppText(
                          text: 'Cancel',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textnaturalcolor,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() => _isOnline = false);
                          if (Get.isRegistered<HomeController>()) {
                            final controller = Get.find<HomeController>();
                            await controller.toggleOnlineStatus(false);
                          }
                          Get.back(result: true);
                          // Close the app
                          SystemNavigator.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primarycolor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 0,
                        ),
                        child: AppText(
                          text: 'Go Offline',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      return result ?? false;
    }
    return true;
  }

  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
                                    onChanged: (val) async {
                                      setState(() => _isOnline = val);
                                      // Call the controller method to sync with API
                                      if (Get.isRegistered<HomeController>()) {
                                        final controller =
                                            Get.find<HomeController>();
                                        await controller.toggleOnlineStatus(
                                          val,
                                        );
                                      }
                                    },
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
                            _buildTab('New', _newOrdersForCount.length, 0),
                            _buildTab(
                              'In Transit',
                              _inTransitOrdersForCount.length,
                              1,
                            ),
                            _buildTab('Returns', _activeReturnOrders.length, 2),
                            _buildTab(
                              'History',
                              _historyOrdersForCount.length +
                                  _historyReturnOrders.length,
                              3,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ─── Search Bar ──────────────────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by customer phone',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[400],
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey[400],
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ─── Order / Return List ──────────────────────────────────────────
                      Expanded(
                        child: _selectedTab == 3
                            ? _buildHistoryList()
                            : (_isReturnTab
                                  ? _buildReturnList()
                                  : _buildDeliveryList()),
                      ),
                    ] else if (_selectedIndex == 1) ...[
                      const Expanded(child: RouteScreen()),
                    ],
                  ],
                ),
              ),

        bottomNavigationBar: _buildCustomBottomNav(),
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

  Widget _buildTab(String label, int count, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTab = index;
          // Reset visible counts on tab switch
          _visibleNewCount = _pageLimit;
          _visibleHistoryCount = _pageLimit;
          _visibleReturnCount = _pageLimit;
        }),
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppText(
                  text: label,
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primarycolor
                      : Colors.grey[600]!,
                  maxLines: 1,
                ),
                if (count > 0)
                  Positioned(
                    top: -10.h,
                    right: -14.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444), // Vibrant Red
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
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
      return RefreshIndicator(
        onRefresh: _fetchOrders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400.h,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon(
                  //   Icons.wifi_off_rounded,
                  //   size: 48.sp,
                  //   color: Colors.grey[400],
                  // ),
                  // SizedBox(height: 12.h),
                  AppText(
                    text: 'No orders here',
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
    final allOrders = _filterDeliveryOrders(_currentOrders);
    final orders = allOrders.take(_visibleNewCount).toList();
    final bool showLoadMore =
        orders.length < allOrders.length ||
        (_hasMoreOrders && allOrders.length >= _pageSize);
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: allOrders.isEmpty
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
              controller: _deliveryScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              itemCount: orders.length + (showLoadMore ? 1 : 0),
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                if (showLoadMore && index == orders.length) {
                  return _AnimatedLoadMoreButton(
                    loading: _loadingMore,
                    onPressed: () {
                      setState(() {
                        if (_visibleNewCount < allOrders.length) {
                          _visibleNewCount += _pageLimit;
                        } else {
                          _currentPage++;
                          _fetchOrders(loadMore: true);
                        }
                      });
                    },
                  );
                }
                return _buildOrderCard(orders[index]);
              },
            ),
    );
  }

  Widget _buildHistoryList() {
    if (_ordersLoading || _returnsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ordersError != null && _returnsError != null) {
      return RefreshIndicator(
        onRefresh: _fetchOrders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400.h,
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
                    text: 'Could not load history',
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
    final allDel = _filterDeliveryOrders(_historyOrders);
    final allRet = _filterReturnOrders(_historyReturnOrders);
    final allCombined = [...allRet, ...allDel];
    final totalAll = allCombined.length;
    final combinedOrders = allCombined.take(_visibleHistoryCount).toList();
    final totalCount = combinedOrders.length;
    final bool showLoadMore =
        totalCount < totalAll || (_hasMoreOrders && totalAll >= _pageSize);
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: totalAll == 0
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400.h,
                child: Center(
                  child: AppText(
                    text: 'No history here',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500]!,
                  ),
                ),
              ),
            )
          : ListView.separated(
              controller: _historyScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              itemCount: totalCount + (showLoadMore ? 1 : 0),
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                if (showLoadMore && index == totalCount) {
                  return _AnimatedLoadMoreButton(
                    loading: _loadingMore,
                    onPressed: () {
                      setState(() {
                        if (_visibleHistoryCount < totalAll) {
                          _visibleHistoryCount += _pageLimit;
                        } else {
                          _currentPage++;
                          _fetchOrders(loadMore: true);
                        }
                      });
                    },
                  );
                }
                final order = combinedOrders[index];
                if (order is ReturnOrder) {
                  return _buildReturnCard(order);
                } else {
                  return _buildOrderCard(order as DeliveryOrder);
                }
              },
            ),
    );
  }

  Widget _buildReturnList() {
    if (_returnsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_returnsError != null) {
      return RefreshIndicator(
        onRefresh: _fetchOrders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400.h,
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
                    text: 'Could not load returns',
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
    final allReturns = _filterReturnOrders(_activeReturnOrders);
    if (allReturns.isEmpty) {
      return Center(
        child: AppText(
          text: 'No active returns',
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500]!,
        ),
      );
    }
    final activeReturns = allReturns.take(_visibleReturnCount).toList();
    final bool showLoadMore =
        activeReturns.length < allReturns.length ||
        (_hasMoreReturns && allReturns.length >= _pageSize);
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.separated(
        controller: _returnScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        itemCount: activeReturns.length + (showLoadMore ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          if (showLoadMore && index == activeReturns.length) {
            return _AnimatedLoadMoreButton(
              loading: _loadingMore,
              onPressed: () {
                setState(() {
                  if (_visibleReturnCount < allReturns.length) {
                    _visibleReturnCount += _pageLimit;
                  } else {
                    _currentPage++;
                    _fetchOrders(loadMore: true);
                  }
                });
              },
            );
          }
          return _buildReturnCard(activeReturns[index]);
        },
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
                  child: () {
                    final String itemStatusClean =
                        (ret.returnItemStatus?.toLowerCase() ?? '').replaceAll(
                          ' ',
                          '_',
                        );

                    final bool isCompleted =
                        itemStatusClean == 'rejected_dropped' ||
                        // Refund completed → rider done
                        (ret.refundStatus?.toLowerCase() == 'completed' ||
                            ret.refundStatus?.toLowerCase() == 'refunded' ||
                            ret.refundStatus?.toLowerCase() == 'success' ||
                            ret.refundStatus?.toLowerCase() == 'processed' ||
                            ret.refundStatus?.toLowerCase() == 'done') ||
                        // Replacement: only show as done when replacement delivery completed
                        (ret.returnType?.toLowerCase() == 'replacement' &&
                            (ret.replacementDeliveryStatus?.toLowerCase() ==
                                    'completed' ||
                                ret.replacementDeliveryStatus?.toLowerCase() ==
                                    'delivered')) ||
                        _historyStatuses.contains(
                          ret.orderStatus.toLowerCase(),
                        );

                    if (isCompleted) {
                      final bool showAsRejectedDropped =
                          itemStatusClean == 'rejected_dropped';
                      final bool isReplacement =
                          ret.returnType?.toLowerCase() == 'replacement';
                      final String completedText = showAsRejectedDropped
                          ? (isReplacement ? 'Replaced' : 'Refunded')
                          : (isReplacement ? 'Replaced' : 'Refunded');
                      return GestureDetector(
                        onTap: () async {
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
                        child: Container(
                          height: 36.h,
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
                                size: 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              AppText(
                                text: completedText,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E7E4C),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SizedBox(
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
                    );
                  }(),
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
            if (order.dispatch != null &&
                order.orderStatus.toLowerCase() != 'delivered') ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    order.isFromWarehouse
                        ? Icons.inventory_2_outlined
                        : Icons.local_shipping_outlined,
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
                          text: order.isFromWarehouse
                              ? 'Warehouse'
                              : 'Delivery Hub',
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
  // ─── Custom Bottom Navigation ──────────────────────────────────────────

  Widget _buildCustomBottomNav() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        10.h,
        16.w,
        10.h + Get.mediaQuery.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(1, Icons.route_outlined, Icons.route, 'Route'),
            _buildNavItem(
              2,
              Icons.account_balance_wallet_outlined,
              Icons.account_balance_wallet,
              'Wallet',
            ),
            _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final bool isSelected = _selectedIndex == index;

    // Determine badge count for specific tabs
    int? badgeCount;
    if (index == 0) {
      badgeCount = _newOrders.length;
    } else if (index == 1) {
      // Route badge shows total active orders (New + In Transit excluding undelivered) + active return orders
      // Deduplicate orders that might appear in both New and In Transit
      final allActiveOrders = [..._newOrders, ..._inTransitOrders];
      final uniqueOrderIds = <String>{};
      final uniqueActiveOrders = allActiveOrders.where((o) {
        if (o.orderStatus.toLowerCase() == 'undelivered') return false;
        if (uniqueOrderIds.contains(o.orderId)) return false;
        uniqueOrderIds.add(o.orderId);
        return true;
      }).toList();
      badgeCount = uniqueActiveOrders.length + _activeReturnOrders.length;
    }

    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() => _selectedIndex = index);
          _loadUserData();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.w : 10.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarycolor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primarycolor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildNavIcon(index, isSelected, icon, activeIcon),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: _buildBadge(badgeCount, isSelected),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuint,
              child: isSelected
                  ? Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: AppText(
                        text: label,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        maxLines: 1,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(int count, bool isSelected) {
    return Container(
      padding: EdgeInsets.all(4.w),
      constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : AppColors.primarycolor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primarycolor : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: isSelected ? AppColors.primarycolor : Colors.white,
            fontSize: 8.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    int index,
    bool isSelected,
    IconData icon,
    IconData activeIcon,
  ) {
    if (index == 3 && _userAvatar != null && _userAvatar!.isNotEmpty) {
      return Container(
        width: 22.w,
        height: 22.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[300]!,
            width: 1.5,
          ),
          image: DecorationImage(
            image: NetworkImage(_userAvatar!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Icon(
      isSelected ? activeIcon : icon,
      color: isSelected ? Colors.white : Colors.grey[400],
      size: 22.sp,
    );
  }
}

// ─── Animated Load More Button ────────────────────────────────────────────────

class _AnimatedLoadMoreButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _AnimatedLoadMoreButton({
    required this.loading,
    required this.onPressed,
  });

  State<_AnimatedLoadMoreButton> createState() =>
      _AnimatedLoadMoreButtonState();
}

class _AnimatedLoadMoreButtonState extends State<_AnimatedLoadMoreButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    // Small delay so it appears after the list is rendered
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _ctrl.forward();
    });
  }

  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.loading ? null : widget.onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primarycolor,
                side: BorderSide(color: AppColors.primarycolor, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                backgroundColor: AppColors.primarycolor.withValues(alpha: 0.04),
              ),
              child: widget.loading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primarycolor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.expand_more_rounded,
                          size: 18.sp,
                          color: AppColors.primarycolor,
                        ),
                        SizedBox(width: 6.w),
                        AppText(
                          text: 'Load More',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primarycolor,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
