import 'dart:convert';

import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/app/utils/network/apiurls.dart';
import 'package:care_mall_rider/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, pi;
import 'package:care_mall_rider/src/modules/home_screen/controller/order_repo.dart';

// ─────────────────────────────────────────────
// Utils
// ─────────────────────────────────────────────

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = pi / 180;
  const r = 6371; // Earth radius in km
  final a =
      0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 2 * r * sqrt(a);
}

// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────

class RouteStop {
  final String orderId;
  final String customerName;
  final String address;
  final String phone;
  final String status;
  final int stopNumber;
  final double? lat;
  final double? lng;

  const RouteStop({
    required this.orderId,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.status,
    required this.stopNumber,
    this.lat,
    this.lng,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    // Safe map extraction – avoids 'List is not a subtype of Map' crashes
    Map<String, dynamic> safeMap(dynamic v) =>
        v is Map<String, dynamic> ? v : {};

    num? safeNum(dynamic v) => v is num ? v : null;

    final customer = safeMap(json['customer']);
    final location = safeMap(
      json['deliveryAddress'] ?? json['location'] ?? json['address'],
    );

    return RouteStop(
      orderId:
          json['orderId']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          '-',
      customerName:
          customer['name']?.toString() ??
          json['customerName']?.toString() ??
          'Unknown',
      address:
          location['street']?.toString() ??
          location['address']?.toString() ??
          location['fullAddress']?.toString() ??
          (json['address'] is String ? json['address'].toString() : null) ??
          '-',
      phone: customer['phone']?.toString() ?? json['phone']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      stopNumber:
          safeNum(json['stopNumber'])?.toInt() ??
          safeNum(json['stop'])?.toInt() ??
          0,
      lat:
          safeNum(json['lat'])?.toDouble() ??
          safeNum(location['lat'])?.toDouble(),
      lng:
          safeNum(json['lng'])?.toDouble() ??
          safeNum(location['lng'])?.toDouble(),
    );
  }
}

class TodayRoute {
  final int totalStops;
  final int remainingStops;
  final double totalDistanceKm;
  final int etaMinutes;
  final double? riderLat;
  final double? riderLng;
  final List<RouteStop> stops;

  const TodayRoute({
    required this.totalStops,
    required this.remainingStops,
    required this.totalDistanceKm,
    required this.etaMinutes,
    this.riderLat,
    this.riderLng,
    required this.stops,
  });

  factory TodayRoute.fromJson(Map<String, dynamic> json) {
    // Try multiple common root keys for the stops list
    final raw =
        json['stops'] ?? json['orders'] ?? json['route'] ?? json['data'] ?? [];
    final rawStops = raw is List ? raw : <dynamic>[];

    final stops = rawStops
        .map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse rider location
    final riderLoc = json['riderLocation'] ?? json['rider_location'];
    double? rLat;
    double? rLng;
    if (riderLoc is Map) {
      rLat =
          (riderLoc['lat'] as num?)?.toDouble() ??
          (riderLoc['latitude'] as num?)?.toDouble();
      rLng =
          (riderLoc['lng'] as num?)?.toDouble() ??
          (riderLoc['longitude'] as num?)?.toDouble();
    }

    double dist =
        (json['totalDistanceKm'] ??
                json['totalDistance'] ??
                json['distance'] ??
                json['total_distance'] as num?)
            ?.toDouble() ??
        0.0;

    int eta =
        (json['etaMinutes'] ??
                json['eta'] ??
                json['duration'] ??
                json['total_duration'] ??
                json['estimated_time'] as num?)
            ?.toInt() ??
        0;

    // Client-side calculation fallback
    if (dist == 0.0 && stops.isNotEmpty && rLat != null && rLng != null) {
      double calculatedDist = 0;
      double currentLat = rLat;
      double currentLng = rLng;

      for (final stop in stops) {
        if (stop.lat != null && stop.lng != null) {
          calculatedDist += _calculateDistance(
            currentLat,
            currentLng,
            stop.lat!,
            stop.lng!,
          );
          currentLat = stop.lat!;
          currentLng = stop.lng!;
        }
      }
      dist = calculatedDist;

      // Estimate ETA: Dist / 30 km/h * 60 min
      if (eta == 0) {
        eta = (dist / 30 * 60).round();
      }
    }

    return TodayRoute(
      totalStops:
          (json['totalStops'] as num?)?.toInt() ??
          (json['total_stops'] as num?)?.toInt() ??
          stops.length,
      remainingStops:
          (json['remainingStops'] as num?)?.toInt() ??
          (json['remaining_stops'] as num?)?.toInt() ??
          stops.where((s) {
            final st = s.status.toLowerCase();
            return st != 'delivered' && st != 'cancelled';
          }).length,
      totalDistanceKm: dist,
      etaMinutes: eta,
      riderLat: rLat,
      riderLng: rLng,
      stops: stops,
    );
  }
}

// ─────────────────────────────────────────────
// Repo helper
// ─────────────────────────────────────────────

Future<TodayRoute> fetchTodayRoute({
  double lat = 11.2588,
  double lng = 75.7804,
}) async {
  final token = await StorageService.getAuthToken();
  final uri = Uri.parse(
    ApiUrls.todayRoute,
  ).replace(queryParameters: {'lat': lat.toString(), 'lng': lng.toString()});

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    try {
      final decoded = jsonDecode(response.body);
      TodayRoute baseRoute;

      // API may return a bare List or a Map wrapping the stops
      if (decoded is List) {
        baseRoute = TodayRoute.fromJson({'stops': decoded});
      } else if (decoded is Map<String, dynamic>) {
        final innerStops =
            decoded['route'] ?? decoded['data'] ?? decoded['stops'];

        if (innerStops is List) {
          baseRoute = TodayRoute.fromJson(decoded);
        } else if (innerStops is Map<String, dynamic>) {
          baseRoute = TodayRoute.fromJson(innerStops);
        } else {
          baseRoute = TodayRoute.fromJson(decoded);
        }
      } else {
        throw Exception('Unexpected JSON shape: ${response.body}');
      }

      // Sync with actual delivery orders to override stale backend statuses
      try {
        final actualOrders = await OrderRepo.getDeliveryOrders();

        List<RouteStop> syncedStops = [];

        // 1. Sync existing backend stops with fresh data
        final existingRouteOrderIds = <String>{};
        for (final stop in baseRoute.stops) {
          final realOrder = actualOrders
              .where((o) => o.orderId == stop.orderId)
              .firstOrNull;

          if (realOrder != null) {
            existingRouteOrderIds.add(stop.orderId);
            syncedStops.add(
              RouteStop(
                orderId: stop.orderId,
                customerName: stop.customerName,
                address: stop.address,
                phone: stop.phone,
                status: realOrder.orderStatus,
                stopNumber: stop.stopNumber,
                lat: stop.lat,
                lng: stop.lng,
              ),
            );
          } else {
            // Keep anyway if not found in current refresh
            syncedStops.add(stop);
          }
        }

        // 2. Append missing "New" and "In Transit" orders
        final missingActiveOrders = actualOrders.where((o) {
          return o.isActive && !existingRouteOrderIds.contains(o.orderId);
        }).toList();

        int nextStopNum = syncedStops.length + 1;
        for (final o in missingActiveOrders) {
          syncedStops.add(
            RouteStop(
              orderId: o.orderId,
              customerName: o.shippingAddress.fullName.isNotEmpty
                  ? o.shippingAddress.fullName
                  : 'Unknown',
              address: o.fullAddress.isNotEmpty ? o.fullAddress : '-',
              phone: o.shippingAddress.phone.isNotEmpty
                  ? o.shippingAddress.phone
                  : '-',
              status: o.orderStatus,
              stopNumber: nextStopNum++,
            ),
          );
        }

        final syncedRemaining = syncedStops.where((s) {
          final st = s.status.toLowerCase();
          return st != 'delivered' && st != 'cancelled' && st != 'failed';
        }).length;

        return TodayRoute(
          totalStops: syncedStops.length,
          remainingStops: syncedRemaining,
          totalDistanceKm: baseRoute.totalDistanceKm,
          etaMinutes: baseRoute.etaMinutes,
          riderLat: baseRoute.riderLat,
          riderLng: baseRoute.riderLng,
          stops: syncedStops,
        );
      } catch (e) {
        debugPrint('Failed to sync route with live orders: $e');
        return baseRoute;
      }
    } catch (e) {
      throw Exception('Parse error: $e\n\nRaw response:\n${response.body}');
    }
  } else {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late Future<TodayRoute> _routeFuture;

  void initState() {
    super.initState();
    _routeFuture = fetchTodayRoute();
  }

  Future<void> _refresh() async {
    setState(() {
      _routeFuture = fetchTodayRoute();
    });
    await _routeFuture;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<TodayRoute>(
        future: _routeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: Colors.red,
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
                          Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                          SizedBox(height: 12.h),
                          AppText(
                            text: 'Could not load today\'s route.',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textnaturalcolor,
                          ),
                          SizedBox(height: 8.h),
                          AppText(
                            text: snapshot.error.toString(),
                            fontSize: 12.sp,
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

          final route = snapshot.data!;
          return _RouteBody(route: route, onRefresh: _refresh);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Body (split out for clarity)
// ─────────────────────────────────────────────

class _RouteBody extends StatelessWidget {
  final TodayRoute route;
  final VoidCallback onRefresh;

  const _RouteBody({required this.route, required this.onRefresh});

  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: Colors.red,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Summary Card ──────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                child: _SummaryCard(route: route),
              ),
            ),
          ),

          // ── Section header ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    text: 'Stops',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textnaturalcolor,
                  ),
                  AppText(
                    text: '${route.stops.length} total',
                    fontSize: 13.sp,
                    color: Colors.grey[500]!,
                  ),
                ],
              ),
            ),
          ),

          // ── Empty state ───────────────────────────────
          if (route.stops.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.route_outlined,
                      size: 64.sp,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      text: 'No stops for today',
                      fontSize: 16.sp,
                      color: Colors.grey[500]!,
                    ),
                  ],
                ),
              ),
            ),

          // ── Stops list ────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final stop = route.stops[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _StopCard(stop: stop, index: index),
                );
              }, childCount: route.stops.length),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final TodayRoute route;

  const _SummaryCard({required this.route});

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
          AppText(text: 'Stops Left', fontSize: 12.sp, color: Colors.white70),
          SizedBox(height: 8.h),
          Row(
            children: [
              _StatChip(
                icon: Icons.location_on_outlined,
                label: '${route.remainingStops} Stops Left',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14.sp),
          SizedBox(width: 4.w),
          AppText(
            text: label,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stop Card
// ─────────────────────────────────────────────

class _StopCard extends StatelessWidget {
  final RouteStop stop;
  final int index;

  const _StopCard({required this.stop, required this.index});

  Color _statusBadgeBg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFE6F4EE);
      case 'cancelled':
      case 'failed':
      case 'undelivered':
        return const Color(0xFFFFE3E3);
      case 'shipped':
      case 'out_for_delivery':
      case 'in_transit':
      case 'in-transit':
      case 'picked_up':
        return const Color(0xFFE8F0FE);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _statusBadgeFg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF1E7E4C);
      case 'cancelled':
      case 'failed':
      case 'undelivered':
        return Colors.red;
      case 'shipped':
      case 'out_for_delivery':
      case 'in_transit':
      case 'in-transit':
      case 'picked_up':
        return const Color(0xFF1A56DB);
      default:
        return const Color(0xFF374151);
    }
  }

  Widget build(BuildContext context) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stop number badge
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: AppText(
              text: '${index + 1}',
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          SizedBox(width: 12.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: 'Order #${stop.orderId}',
                      fontSize: 12.sp,
                      color: Colors.grey[500]!,
                      fontWeight: FontWeight.w500,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBadgeBg(stop.status),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: AppText(
                        text: stop.status.replaceAll('_', ' ').toUpperCase(),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _statusBadgeFg(stop.status),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSans(
                      fontSize: 14.sp,
                      color: AppColors.textnaturalcolor,
                    ),
                    children: [
                      TextSpan(
                        text: stop.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                AppText(
                  text: stop.address,
                  fontSize: 12.sp,
                  color: Colors.grey[600]!,
                ),
                if (stop.phone != '-') ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13.sp,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4.w),
                      AppText(
                        text: stop.phone,
                        fontSize: 12.sp,
                        color: Colors.grey[500]!,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
