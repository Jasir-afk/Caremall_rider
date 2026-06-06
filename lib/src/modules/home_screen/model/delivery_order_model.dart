class DeliveryOrder {
  final String id;
  final String orderId;
  final String orderStatus;
  final double totalAmount;
  final String paymentMethod;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final ShippingAddress shippingAddress;
  final DispatchInfo? dispatch;
  final List<OrderItem> items;
  final bool undeliveredWarehouseDrop;
  DeliveryOrder({
    required this.id,
    required this.orderId,
    required this.orderStatus,
    required this.totalAmount,
    required this.paymentMethod,
    required this.isDelivered,
    this.deliveredAt,
    required this.shippingAddress,
    this.dispatch,
    this.items = const [],
    this.undeliveredWarehouseDrop = false,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return DeliveryOrder(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      orderStatus: json['orderStatus'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      isDelivered: json['isDelivered'] ?? false,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      shippingAddress: ShippingAddress.fromJson(json['shippingAddress'] ?? {}),
      dispatch: json['dispatch'] != null
          ? DispatchInfo.fromJson(json['dispatch'])
          : null,
      items: rawItems
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      undeliveredWarehouseDrop: json['undeliveredWarehouseDrop'] ?? false,
    );
  }

  /// Is this a Cash on Delivery order?
  bool get isCod => paymentMethod.toLowerCase() == 'cod';

  /// Human-readable delivery address
  String get fullAddress {
    final a = shippingAddress;
    final parts = [
      a.fullName,
      a.addressLine1,
      if (a.addressLine2.isNotEmpty) a.addressLine2,
      a.city,
      a.state,
      a.postalCode,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Is this order in the "New" tab (not yet picked up)?
  bool get isInNewStatus {
    const newStatuses = {
      'pending',
      'confirmed',
      'processing',
      'dispatched',
      'assigned',
      'accepted',
      'new',
    };
    return newStatuses.contains(orderStatus.toLowerCase());
  }

  /// Is this order in the "In Transit" tab?
  bool get isInTransitStatus {
    const transitStatuses = {
      'shipped',
      'shipping',
      'out_for_delivery',
      'in_transit',
      'in-transit',
      'picked_up',
      'undelivered',
    };
    return transitStatuses.contains(orderStatus.toLowerCase());
  }

  /// Is this order active (either New or In Transit)?
  bool get isActive => isInNewStatus || isInTransitStatus;

  /// The amount that actually needs to be collected.
  /// If COD, add a 40 rupees charge.
  double get amountToCollect => isCod ? totalAmount + 40 : totalAmount;
}

class OrderItem {
  final String id;
  final String productId;
  final String? productImage; // first available image from the product object
  final int quantity;
  final double sellingPrice;
  final double mrpPrice;
  final double totalPrice;
  final double taxRate;
  final double discountAmount;
  final double taxAmount;
  final double netAmount;

  OrderItem({
    required this.id,
    required this.productId,
    this.productImage,
    required this.quantity,
    required this.sellingPrice,
    required this.mrpPrice,
    required this.totalPrice,
    required this.taxRate,
    required this.discountAmount,
    required this.taxAmount,
    required this.netAmount,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    String productId = '';
    String? productImage;

    if (product is Map) {
      productId = (product['_id'] ?? '').toString();
      // Try common image field names returned by e-commerce APIs
      productImage =
          product['thumbnail'] as String? ??
          product['image'] as String? ??
          product['imageUrl'] as String?;

      // Fallback: first item of an images array
      if (productImage == null) {
        final images = product['images'];
        if (images is List && images.isNotEmpty) {
          final first = images.first;
          productImage = first is String
              ? first
              : (first is Map ? first['url'] as String? : null);
        }
      }
    }

    return OrderItem(
      id: json['_id'] ?? '',
      productId: productId,
      productImage: productImage,
      quantity: json['quantity'] ?? 0,
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      mrpPrice: (json['mrpPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
    );
  }
}

class ShippingAddress {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String landmark;
  final String district;

  ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.landmark,
    required this.district,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
      landmark: json['landmark'] ?? '',
      district: json['district'] ?? '',
    );
  }
}

class DispatchInfo {
  final String dispatchType;
  final String vehicleNumber;
  final String destination;
  final int totalPackages;
  final double totalWeight;
  final double amount;
  final String status;
  final DateTime? dispatchDate;

  DispatchInfo({
    required this.dispatchType,
    required this.vehicleNumber,
    required this.destination,
    required this.totalPackages,
    required this.totalWeight,
    required this.amount,
    required this.status,
    this.dispatchDate,
  });

  factory DispatchInfo.fromJson(Map<String, dynamic> json) {
    return DispatchInfo(
      dispatchType: json['dispatchType'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      destination: json['destination'] ?? '',
      totalPackages: json['totalPackages'] ?? 0,
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      dispatchDate: json['dispatchDate'] != null
          ? DateTime.tryParse(json['dispatchDate'])
          : null,
    );
  }
}
