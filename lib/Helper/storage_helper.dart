import 'package:shared_preferences/shared_preferences.dart';

import 'app_constants.dart';

class StorageHelper {
  const StorageHelper._();

  static Future<void> saveAuthToken({
    required String accessToken,
    required String tokenType,
    required int expiresIn,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(AppConstants.accessTokenKey, accessToken);
    await preferences.setString(AppConstants.tokenTypeKey, tokenType);
    await preferences.setInt(AppConstants.expiresInKey, expiresIn);
  }

  static Future<String?> getAccessToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(AppConstants.accessTokenKey);
  }

  static Future<String?> getTokenType() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(AppConstants.tokenTypeKey);
  }

  static Future<void> clearAuthToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(AppConstants.accessTokenKey);
    await preferences.remove(AppConstants.tokenTypeKey);
    await preferences.remove(AppConstants.expiresInKey);
  }
}
