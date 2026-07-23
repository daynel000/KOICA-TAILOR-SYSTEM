import 'package:shared_preferences/shared_preferences.dart';

/// Session manager for the logged-in Tailor user.
class TailorSession {
  static const String _keyUserId     = 'tailor_user_id';
  static const String _keyProfileId  = 'tailor_profile_id';
  static const String _keyFullName   = 'tailor_full_name';
  static const String _keyShopName   = 'tailor_shop_name';

  static int?    currentTailorId;
  static int?    currentProfileId;
  static String? currentFullName;
  static String? currentShopName;

  /// Load persisted session from SharedPreferences on app startup.
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    currentTailorId  = prefs.getInt(_keyUserId);
    currentProfileId = prefs.getInt(_keyProfileId);
    currentFullName  = prefs.getString(_keyFullName);
    currentShopName  = prefs.getString(_keyShopName);
  }

  /// Save session after a successful tailor login.
  static Future<void> saveSession({
    required int    userId,
    required int    profileId,
    required String fullName,
    required String shopName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId,      userId);
    await prefs.setInt(_keyProfileId,   profileId);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyShopName, shopName);

    currentTailorId  = userId;
    currentProfileId = profileId;
    currentFullName  = fullName;
    currentShopName  = shopName;
  }

  /// Clear session on logout.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyProfileId);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyShopName);

    currentTailorId  = null;
    currentProfileId = null;
    currentFullName  = null;
    currentShopName  = null;
  }

  /// Returns true if a tailor is currently logged in.
  static bool isLoggedIn() => currentTailorId != null;
}
