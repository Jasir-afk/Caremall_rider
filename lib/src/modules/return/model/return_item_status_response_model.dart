class ReturnItemStatusResponse {
  final String? message;
  final String? returnItemStatus;

  ReturnItemStatusResponse({this.message, this.returnItemStatus});

  factory ReturnItemStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['returnItemStatus']?.toString();
    final returnItemStatus = (rawStatus?.toLowerCase() == 'sent' ||
                              rawStatus?.toLowerCase() == 'received')
        ? 'dropped'
        : rawStatus;
    return ReturnItemStatusResponse(
      message: json['message']?.toString(),
      returnItemStatus: returnItemStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (message != null) 'message': message,
      if (returnItemStatus != null) 'returnItemStatus': returnItemStatus,
    };
  }
}
