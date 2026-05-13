class ReturnItemStatusResponse {
  final String? message;
  final String? returnItemStatus;

  ReturnItemStatusResponse({
    this.message,
    this.returnItemStatus,
  });

  factory ReturnItemStatusResponse.fromJson(Map<String, dynamic> json) {
    return ReturnItemStatusResponse(
      message: json['message']?.toString(),
      returnItemStatus: json['returnItemStatus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (message != null) 'message': message,
      if (returnItemStatus != null) 'returnItemStatus': returnItemStatus,
    };
  }
}
