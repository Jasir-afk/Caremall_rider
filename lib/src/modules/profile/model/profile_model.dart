class RiderProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String avatar;
  final String address;
  final String status;
  final String kycStatus;
  // Vehicle
  final String vehicleType;
  final String registrationNumber;
  // Bank / UPI
  final String paymentMode;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String upiId;
  final String upiNumber;

  const RiderProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.avatar,
    required this.status,
    required this.kycStatus,
    required this.vehicleType,
    required this.registrationNumber,
    required this.paymentMode,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    required this.upiId,
    required this.upiNumber,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    final kyc = json['kyc'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicleDetails'] as Map<String, dynamic>? ?? {};
    final bank = json['bankDetails'] as Map<String, dynamic>? ?? {};
    return RiderProfile(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Rider',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      kycStatus: kyc['status']?.toString() ?? '-',
      vehicleType: vehicle['vehicleType']?.toString() ?? '-',
      registrationNumber: vehicle['registrationNumber']?.toString() ?? '',
      paymentMode: bank['paymentMode']?.toString() ?? 'bank',
      accountHolderName: bank['accountHolderName']?.toString() ?? '',
      accountNumber: bank['accountNumber']?.toString() ?? '',
      ifscCode: bank['ifscCode']?.toString() ?? '',
      bankName: bank['bankName']?.toString() ?? '',
      upiId: bank['upiId']?.toString() ?? '',
      upiNumber: bank['upiNumber']?.toString() ?? '',
    );
  }
}
