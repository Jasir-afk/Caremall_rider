class ApiUrls {
  // Base URL
  static String baseURL = 'https://test.api.caremallonline.com';
  // static const String baseURL = 'http://192.168.1.5:3000';

  // Auth
  static String sendOtp =
      '$baseURL/api/v1/rider/auth/send-otp'; // POST – send OTP to rider
  static String login =
      '$baseURL/api/v1/rider/auth/login'; // POST – login with phone and OTP
  static String verifyOtp =
      '$baseURL/api/v1/rider/auth/verify-otp'; // POST – verify OTP
  static String register =
      '$baseURL/api/v1/rider/auth/register'; // POST – register new rider
  static String resendOtp =
      '$baseURL/api/v1/rider/auth/resend-otp'; // POST – resend OTP
  static String logout =
      '$baseURL/api/v1/rider/auth/logout'; // POST – logout rider

  // Kyc
  static String kycSubmit =
      '$baseURL/api/v1/rider/kyc/submit'; // POST – submit kyc
  static String kycStatus =
      '$baseURL/api/v1/rider/kyc/status'; // GET – get kyc status

  // Common – image upload uses the production CDN server directly
  static const String uploadImage =
      'https://api.caremall.in/api/v1/admin/upload/image'; // POST – upload image

  // Routes
  static String todayRoute =
      '$baseURL/api/v1/rider/routes/today'; // GET – today's route with ?lat=&lng=

  // Orders
  static String deliveryOrders =
      '$baseURL/api/v1/rider/delivery/orders'; // GET – list all assigned orders
  static String dashboard =
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
  static String returnsOrders =
      '$baseURL/api/v1/rider/returns'; // GET – return orders list
  static String returnDetail(String id) =>
      '$baseURL/api/v1/rider/returns/$id'; // GET – single return order
  static String returnUpdateStatus(String id) =>
      '$baseURL/api/v1/rider/returns/$id/status'; // PATCH – update return status
  static String returnUploadPhoto(String id) =>
      '$baseURL/api/v1/rider/returns/$id/upload-photo'; // POST – upload return photo

  // Wallet
  static String wallet = '$baseURL/api/v1/rider/wallet'; // GET – get wallet
  static String withdraw =
      '$baseURL/api/v1/rider/wallet/withdraw'; // POST – withdraw
  static String withdrawalRequests =
      '$baseURL/api/v1/rider/wallet/requests'; // GET – get withdrawal requests

  // Profile
  static String getProfile =
      '$baseURL/api/v1/rider/auth/me'; // GET – get rider profile
  static String updateProfile =
      '$baseURL/api/v1/rider/auth/me'; // PATCH – update rider profile
}
