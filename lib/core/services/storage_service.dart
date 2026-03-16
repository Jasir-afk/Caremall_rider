import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling persistent storage using SharedPreferences
class StorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _kycStatusKey = 'kyc_status';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance (initialize if not already done)
  static Future<SharedPreferences> get _instance async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  /// Save authentication token
  static Future<bool> saveAuthToken(String token) async {
    final prefs = await _instance;
    return await prefs.setString(_authTokenKey, token);
  }

  /// Get saved authentication token
  static Future<String?> getAuthToken() async {
    final prefs = await _instance;
    return prefs.getString(_authTokenKey);
  }

  /// Save phone number
  static Future<bool> savePhoneNumber(String phone) async {
    final prefs = await _instance;
    return await prefs.setString(_phoneNumberKey, phone);
  }

  /// Get saved phone number
  static Future<String?> getPhoneNumber() async {
    final prefs = await _instance;
    return prefs.getString(_phoneNumberKey);
  }

  /// Save user name
  static Future<bool> saveUserName(String name) async {
    final prefs = await _instance;
    return await prefs.setString(_userNameKey, name);
  }

  /// Get saved user name
  static Future<String?> getUserName() async {
    final prefs = await _instance;
    return prefs.getString(_userNameKey);
  }

  /// Save user email
  static Future<bool> saveUserEmail(String email) async {
    final prefs = await _instance;
    return await prefs.setString(_userEmailKey, email);
  }

  /// Get saved user email
  static Future<String?> getUserEmail() async {
    final prefs = await _instance;
    return prefs.getString(_userEmailKey);
  }

  /// Mark KYC as completed (legacy support, now sets status to under_review)
  static Future<bool> saveKycCompleted(bool completed) async {
    if (completed) {
      return await saveKycStatus('under_review');
    }
    return true;
  }

  /// Check if KYC has been completed
  static Future<bool> isKycCompleted() async {
    final status = await getKycStatus();
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'verified' ||
        lowerStatus == 'under_review' ||
        lowerStatus == 'approved';
  }

  /// Save KYC status (pending, under_review, verified, rejected)
  static Future<bool> saveKycStatus(String status) async {
    final prefs = await _instance;
    return await prefs.setString(_kycStatusKey, status);
  }

  /// Get saved KYC status
  static Future<String> getKycStatus() async {
    final prefs = await _instance;
    return prefs.getString(_kycStatusKey) ?? 'pending';
  }

  /// Clear all authentication data
  static Future<bool> clearAuthData() async {
    final prefs = await _instance;
    await prefs.remove(_authTokenKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_kycStatusKey);
    return true;
  }

  /// Check if user is logged in (has valid token)
  static Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
