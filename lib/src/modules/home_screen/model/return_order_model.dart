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
  final List<String>? pickupPhotos;
  final double? refundAmount;
  final String? returnType;
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? user;

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
    this.pickupPhotos,
    this.refundAmount,
    this.returnType,
    this.order,
    this.user,
  });

  factory ReturnOrder.fromJson(Map<String, dynamic> json) {
    // Support both top-level and nested customer / address data
    final customer = json['customer'] ?? json['user'];
    final orderObj = json['order'];
    
    final shipping = json['shippingAddress'] ?? json['address'] ?? 
        (orderObj != null && orderObj is Map ? (orderObj['shippingAddress'] ?? orderObj['address']) : null);

    String customerName = '';
    String customerPhone = '';
    String address = '';

    if (customer is Map) {
      if (customer.containsKey('firstName') || customer.containsKey('lastName')) {
        customerName = '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
      } else if (customer.containsKey('name')) {
        customerName = customer['name']?.toString() ?? '';
      }
      customerPhone = (customer['phone'] ?? '').toString();
    }
    
    if (shipping is Map) {
      if (customerName.isEmpty) {
        customerName = '${shipping['fullName'] ?? shipping['firstName'] ?? ''}'.trim();
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
    double parsedTotalAmount = json['totalAmount'] != null ? json['totalAmount'].toDouble() : 
                               (json['amount'] != null ? json['amount'].toDouble() : 
                               (orderObj != null && orderObj is Map && orderObj['totalAmount'] != null ? orderObj['totalAmount'].toDouble() : parsedRefundAmount));

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
      returnItemStatus: json['returnItemStatus']?.toString(),
      pickupPhotos: (json['pickupPhotos'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      refundAmount: parsedRefundAmount,
      returnType: json['returnType']?.toString(),
      order: orderObj is Map<String, dynamic> ? orderObj : null,
      user: customer is Map<String, dynamic> ? customer : null,
    );
  }
}
