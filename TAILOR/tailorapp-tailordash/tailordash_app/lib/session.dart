import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static const String _keyUserId = 'user_id';
  static const String _keyProfileId = 'profile_id';
  static const String _keyFullName = 'full_name';
  static const String _keyShopName = 'shop_name';

  static int? currentTailorId;
  static int? currentProfileId;
  static String? currentFullName;
  static String? currentShopName;

  /// Load session from SharedPreferences
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    currentTailorId = prefs.getInt(_keyUserId);
    currentProfileId = prefs.getInt(_keyProfileId);
    currentFullName = prefs.getString(_keyFullName);
    currentShopName = prefs.getString(_keyShopName);
  }

  /// Save session after login/register
  static Future<void> saveSession({
    required int userId,
    required int profileId,
    required String fullName,
    required String shopName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setInt(_keyProfileId, profileId);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyShopName, shopName);

    currentTailorId = userId;
    currentProfileId = profileId;
    currentFullName = fullName;
    currentShopName = shopName;
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    currentTailorId = null;
    currentProfileId = null;
    currentFullName = null;
    currentShopName = null;
  }

  /// Check if a user is logged in
  static bool isLoggedIn() {
    return currentTailorId != null;
  }
}
