class ApiUrls {
  // Base URL
  static String baseURL = 'https://test.api.caremallonline.com';
  // static const String baseURL = 'http://192.168.1.5:3000';
  // Auth
  static String get sendOtp =>
      '$baseURL/api/v1/rider/auth/send-otp'; // POST – send OTP to rider
  static String get login =>
      '$baseURL/api/v1/rider/auth/login'; // POST – login with phone and OTP
  static String get verifyOtp =>
      '$baseURL/api/v1/rider/auth/verify-otp'; // POST – verify OTP
  static String get register =>
      '$baseURL/api/v1/rider/auth/register'; // POST – register new rider
  static String get resendOtp =>
      '$baseURL/api/v1/rider/auth/resend-otp'; // POST – resend OTP
  static String get logout =>
      '$baseURL/api/v1/rider/auth/logout'; // POST – logout rider

  // Kyc
  static String get kycSubmit =>
      '$baseURL/api/v1/rider/kyc/submit'; // POST – submit kyc
  static String get kycStatus =>
      '$baseURL/api/v1/rider/kyc/status'; // GET – get kyc status

  // Common – image upload uses the production CDN server directly
  static final String uploadImage =
      '$baseURL/api/v1/admin/upload/image'; // POST – upload image

  // Routes
  static String get todayRoute =>
      '$baseURL/api/v1/rider/routes/today'; // GET – today's route with ?lat=&lng=

  // Orders
  static String get deliveryOrders =>
      '$baseURL/api/v1/rider/delivery/orders'; // GET – list all assigned orders
  static String get dashboard =>
      '$baseURL/api/v1/rider/delivery/dashboard'; // GET – dashboard stats
  static String orderDetail(String id) =>
      '$baseURL/api/v1/rider/delivery/orders/$id'; // GET – single order detail
  static String orderUpdateStatus(String id) =>
      '$baseURL/api/v1/rider/delivery/orders/$id/status'; // PATCH – update order status
  static String orderUploadPhoto(String id) =>
      '$baseURL/api/v1/rider/delivery/orders/$id/upload-photo'; // POST – upload delivery photo
  static String orderFailed(String id) =>
      '$baseURL/api/v1/rider/delivery/orders/$id/failed'; // POST – report delivery failure
  static String orderSendOTP(String id) =>
      '$baseURL/api/v1/rider/delivery/orders/$id/send-otp'; // POST – send delivery OTP
  static String orderVerifyOTP(String id) =>
      '$baseURL/api/v1/rider/delivery/orders/$id/complete'; // POST – verify OTP and complete

  // Returns
  static String get returnsOrders =>
      '$baseURL/api/v1/rider/returns'; // GET – return orders list
  static String returnDetail(String id) =>
      '$baseURL/api/v1/rider/returns/$id'; // GET – single return order
  static String returnUpdateStatus(String id) =>
      '$baseURL/api/v1/rider/returns/$id/status'; // PATCH – update return status
  static String returnUpdateItemStatus(String id) =>
      '$baseURL/api/v1/rider/returns/$id/item-status'; // PATCH – update return item status
  static String returnUploadPhoto(String id) =>
      '$baseURL/api/v1/rider/returns/$id/upload-photo'; // POST – upload return photo
  static String returnUpdateReplacementStatus(String id) =>
      '$baseURL/api/v1/rider/returns/$id/replacement-status'; // PATCH – update replacement delivery status

  // Wallet
  static String get wallet =>
      '$baseURL/api/v1/rider/wallet'; // GET – get wallet
  static String get withdraw =>
      '$baseURL/api/v1/rider/wallet/withdraw'; // POST – withdraw
  static String get withdrawalRequests =>
      '$baseURL/api/v1/rider/wallet/requests'; // GET – get withdrawal requests

  // Profile
  static String get getProfile =>
      '$baseURL/api/v1/rider/auth/me'; // GET – get rider profile
  static String get updateProfile =>
      '$baseURL/api/v1/rider/auth/me'; // PATCH – update rider profile
}
