class ReturnStatusResponse {
  final String? message;
  final String? pickupStatus;
  final String? returnStatus;
  final double? walletCredited;
  final double? walletBalance;

  ReturnStatusResponse({
    this.message,
    this.pickupStatus,
    this.returnStatus,
    this.walletCredited,
    this.walletBalance,
  });

  factory ReturnStatusResponse.fromJson(Map<String, dynamic> json) {
    return ReturnStatusResponse(
      message: json['message']?.toString(),
      pickupStatus: json['pickupStatus']?.toString(),
      returnStatus: json['returnStatus']?.toString(),
      walletCredited: json['walletCredited'] != null
          ? double.tryParse(json['walletCredited'].toString())
          : null,
      walletBalance: json['walletBalance'] != null
          ? double.tryParse(json['walletBalance'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (message != null) 'message': message,
      if (pickupStatus != null) 'pickupStatus': pickupStatus,
      if (returnStatus != null) 'returnStatus': returnStatus,
      if (walletCredited != null) 'walletCredited': walletCredited,
      if (walletBalance != null) 'walletBalance': walletBalance,
    };
  }
}
