import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../model/app/public_branding_model.dart';

class SessionStorage {
  const SessionStorage._();

  static const String authTokenKey = 'auth_token';
  static const String tokenTypeKey = 'token_type';
  static const String expiresInKey = 'expires_in';
  static const String expiresAtKey = 'expires_at';
  static const String rememberMeKey = 'remember_me';
  static const String currentUserKey = 'current_user';
  static const String publicBrandingKey = 'public_branding';
  static const String currentCompanyIdKey = 'current_company_id';
  static const String currentBranchIdKey = 'current_branch_id';
  static const String currentLocationIdKey = 'current_location_id';
  static const String currentFinancialYearIdKey = 'current_financial_year_id';

  static Future<void> saveSession({
    required String token,
    required String tokenType,
    required int expiresIn,
    Map<String, dynamic>? currentUser,
    bool rememberMe = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(authTokenKey, token);
    await preferences.setString(tokenTypeKey, tokenType);
    await preferences.setInt(expiresInKey, expiresIn);
    await preferences.setString(
      expiresAtKey,
      DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
    );
    await preferences.setBool(rememberMeKey, rememberMe);

    if (currentUser != null) {
      await preferences.setString(currentUserKey, jsonEncode(currentUser));
    }
  }

  static Future<String?> getAuthToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(authTokenKey);
  }

  static Future<String?> getTokenType() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(tokenTypeKey);
  }

  static Future<DateTime?> getExpiresAt() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(expiresAtKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
  }

  static Future<bool> shouldAutoLogin() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(rememberMeKey) ?? false;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(currentUserKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static Future<void> saveSelectedContext({
    int? companyId,
    int? branchId,
    int? locationId,
    int? financialYearId,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    if (companyId != null) {
      await preferences.setInt(currentCompanyIdKey, companyId);
    }
    if (branchId != null) {
      await preferences.setInt(currentBranchIdKey, branchId);
    }
    if (locationId != null) {
      await preferences.setInt(currentLocationIdKey, locationId);
    }
    if (financialYearId != null) {
      await preferences.setInt(currentFinancialYearIdKey, financialYearId);
    }
  }

  static Future<void> saveBranding(PublicBrandingModel branding) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      publicBrandingKey,
      jsonEncode(branding.toJson()),
    );
  }

  static Future<PublicBrandingModel?> getBranding() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(publicBrandingKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return PublicBrandingModel.fromJson(decoded);
  }

  static Future<void> clearSessionOnly() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(authTokenKey);
    await preferences.remove(tokenTypeKey);
    await preferences.remove(expiresInKey);
    await preferences.remove(expiresAtKey);
    await preferences.remove(rememberMeKey);
    await preferences.remove(currentUserKey);
    await preferences.remove(currentCompanyIdKey);
    await preferences.remove(currentBranchIdKey);
    await preferences.remove(currentLocationIdKey);
    await preferences.remove(currentFinancialYearIdKey);
  }

  static Future<void> clear() async {
    await clearSessionOnly();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(publicBrandingKey);
  }
}
