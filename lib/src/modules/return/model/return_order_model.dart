import 'package:care_mall_rider/src/modules/home_screen/model/delivery_order_model.dart';

class ReturnOrder {
  final String id;
  final String returnId;
  final String orderStatus;
  final String? reason;
  final double totalAmount;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final DateTime? createdAt;
  final String? pickupStatus;
  final String? returnItemStatus;
  final String? refundStatus;
  final String? pickStatus;
  final String? replacementDeliveryStatus;
  final List<String>? pickupPhotos;
  final double? refundAmount;
  final String? returnType;
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? user;
  final bool isPicked;
  final bool isDropped;
  ReturnOrder({
    required this.id,
    required this.returnId,
    required this.orderStatus,
    this.reason,
    required this.totalAmount,
    this.customerName,
    this.customerPhone,
    this.address,
    this.createdAt,
    this.pickupStatus,
    this.returnItemStatus,
    this.refundStatus,
    this.pickStatus,
    this.replacementDeliveryStatus,
    this.pickupPhotos,
    this.refundAmount,
    this.returnType,
    this.order,
    this.user,
    this.isPicked = false,
    this.isDropped = false,
  });
  factory ReturnOrder.fromJson(Map<String, dynamic> json) {
    // Support both top-level and nested customer / address data
    final customer = json['customer'] ?? json['user'];
    final orderObj = json['order'];

    final shipping =
        json['shippingAddress'] ??
        json['address'] ??
        (orderObj != null && orderObj is Map
            ? (orderObj['shippingAddress'] ?? orderObj['address'])
            : null);
    String customerName = '';
    String customerPhone = '';
    String address = '';
    if (customer is Map) {
      if (customer.containsKey('firstName') ||
          customer.containsKey('lastName')) {
        customerName =
            '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
                .trim();
      } else if (customer.containsKey('name')) {
        customerName = customer['name']?.toString() ?? '';
      }
      customerPhone = (customer['phone'] ?? '').toString();
    }

    if (shipping is Map) {
      if (customerName.isEmpty) {
        customerName = '${shipping['fullName'] ?? shipping['firstName'] ?? ''}'
            .trim();
      }
      if (customerPhone.isEmpty) {
        customerPhone = (shipping['phone'] ?? '').toString();
      }
      final parts = [
        shipping['addressLine1'],
        shipping['addressLine2'],
        shipping['city'],
        shipping['state'],
        shipping['pincode'],
      ].where((p) => p != null && p.toString().isNotEmpty).toList();
      address = parts.join(', ');
    }

    final parsedRefundAmount = (json['refundAmount'] ?? 0).toDouble();

    // Try every known field name a backend might use for the order value.
    // Replacement orders often have no 'refundAmount', so we must look wider.
    double? tryDouble(dynamic v) {
      if (v == null) return null;
      final d = double.tryParse(v.toString());
      return (d != null && d > 0) ? d : null;
    }

    double parsedTotalAmount =
        // 1. Top-level explicit amount fields
        tryDouble(json['totalAmount']) ??
        tryDouble(json['amount']) ??
        tryDouble(json['replacementAmount']) ??
        tryDouble(json['orderAmount']) ??
        tryDouble(json['itemAmount']) ??
        // 2. Nested order object
        (orderObj is Map
            ? (tryDouble(orderObj['totalAmount']) ??
                  tryDouble(orderObj['amount']) ??
                  tryDouble(orderObj['subTotal']) ??
                  tryDouble(orderObj['subtotal']) ??
                  tryDouble(orderObj['orderTotal']))
            : null) ??
        // 3. Sum items array if present
        (() {
          final items =
              json['items'] ?? (orderObj is Map ? orderObj['items'] : null);
          if (items is List && items.isNotEmpty) {
            double sum = 0;
            for (final item in items) {
              if (item is Map) {
                final price =
                    double.tryParse(
                      (item['price'] ??
                              item['amount'] ??
                              item['totalPrice'] ??
                              0)
                          .toString(),
                    ) ??
                    0;
                final qty =
                    double.tryParse(
                      (item['quantity'] ?? item['qty'] ?? 1).toString(),
                    ) ??
                    1;
                sum += price * qty;
              }
            }
            if (sum > 0) return sum;
          }
          return null;
        })() ??
        // 4. Last resort: refundAmount (for refund orders; 0 for replacements)
        parsedRefundAmount;

    final rawReturnItemStatus = json['returnItemStatus']?.toString();
    final returnItemStatus = (rawReturnItemStatus?.toLowerCase() == 'sent' ||
                              rawReturnItemStatus?.toLowerCase() == 'received')
        ? 'dropped'
        : rawReturnItemStatus;

    return ReturnOrder(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      returnId: (json['returnId'] ?? json['_id'] ?? '').toString(),
      orderStatus: (json['status'] ?? json['orderStatus'] ?? 'pending')
          .toString()
          .toLowerCase(),
      reason: json['reason']?.toString(),
      totalAmount: parsedTotalAmount,
      customerName: customerName.isEmpty ? null : customerName,
      customerPhone: customerPhone.isEmpty ? null : customerPhone,
      address: address.isEmpty ? null : address,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      pickupStatus: json['pickupStatus']?.toString(),
      returnItemStatus: returnItemStatus,
      refundStatus: json['refundStatus']?.toString(),
      pickStatus: json['pickStatus']?.toString(),
      replacementDeliveryStatus: json['replacementDeliveryStatus']?.toString(),
      pickupPhotos: (json['pickupPhotos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      refundAmount: parsedRefundAmount,
      returnType: (json['returnType'] ?? json['requestType'] ?? 'return')
          .toString(),
      order: orderObj is Map<String, dynamic> ? orderObj : null,
      user: customer is Map<String, dynamic> ? customer : null,
      isPicked:
          json['isPicked'] == true ||
          (returnItemStatus?.toLowerCase().contains('picked') ?? false) ||
          (returnItemStatus?.toLowerCase().contains('received') ?? false) ||
          (returnItemStatus?.toLowerCase().contains('dropped') ?? false),
      isDropped:
          json['isDropped'] == true ||
          (returnItemStatus?.toLowerCase().contains('dropped') ?? false),
    );
  }

  ReturnOrder copyWith({
    String? orderStatus,
    String? returnItemStatus,
    String? replacementDeliveryStatus,
    bool? isPicked,
    bool? isDropped,
  }) {
    return ReturnOrder(
      id: id,
      returnId: returnId,
      orderStatus: orderStatus ?? this.orderStatus,
      reason: reason,
      totalAmount: totalAmount,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      createdAt: createdAt,
      pickupStatus: pickupStatus,
      returnItemStatus: returnItemStatus ?? this.returnItemStatus,
      refundStatus: refundStatus,
      pickStatus: pickStatus,
      replacementDeliveryStatus:
          replacementDeliveryStatus ?? this.replacementDeliveryStatus,
      pickupPhotos: pickupPhotos,
      refundAmount: refundAmount,
      returnType: returnType,
      order: order,
      user: user,
      isPicked: isPicked ?? this.isPicked,
      isDropped: isDropped ?? this.isDropped,
    );
  }

  factory ReturnOrder.fromDeliveryOrder(DeliveryOrder order) {
    return ReturnOrder(
      id: order.id,
      returnId: order.orderId,
      orderStatus: order.orderStatus,
      totalAmount: order.totalAmount,
      customerName: order.shippingAddress.fullName,
      customerPhone: order.shippingAddress.phone,
      address: order.fullAddress,
      createdAt: null,
      refundStatus: 'pending',
      pickStatus: 'pending',
      returnType: 'refund',
      isPicked: false,
      isDropped: false,
    );
  }
}
