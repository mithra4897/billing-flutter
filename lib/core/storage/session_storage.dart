import '../../screen.dart';

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
  static const String currentWarehouseIdKey = 'current_warehouse_id';
  static const String currentFinancialYearIdKey = 'current_financial_year_id';
  static const String authContextKey = 'auth_context';
  static const String permissionCodesKey = 'permission_codes';
  static const String masterDataCacheEnabledKey = 'master_data_cache_enabled';

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

  static Future<bool> hasActiveSession() async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final expiresAt = await getExpiresAt();
    if (expiresAt == null) {
      return false;
    }

    return expiresAt.isAfter(DateTime.now());
  }

  static Future<bool> hasRestorableSession() async {
    return (await shouldAutoLogin()) && (await hasActiveSession());
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

  static Future<void> saveCurrentUser(Map<String, dynamic> currentUser) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(currentUserKey, jsonEncode(currentUser));
  }

  static Future<void> saveSelectedContext({
    int? companyId,
    int? branchId,
    int? locationId,
    int? warehouseId,
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
    if (warehouseId != null) {
      await preferences.setInt(currentWarehouseIdKey, warehouseId);
    }
    if (financialYearId != null) {
      await preferences.setInt(currentFinancialYearIdKey, financialYearId);
    }
  }

  static Future<void> replaceSelectedContext({
    required int? companyId,
    required int? branchId,
    required int? locationId,
    required int? warehouseId,
    required int? financialYearId,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    if (companyId != null) {
      await preferences.setInt(currentCompanyIdKey, companyId);
    } else {
      await preferences.remove(currentCompanyIdKey);
    }
    if (branchId != null) {
      await preferences.setInt(currentBranchIdKey, branchId);
    } else {
      await preferences.remove(currentBranchIdKey);
    }
    if (locationId != null) {
      await preferences.setInt(currentLocationIdKey, locationId);
    } else {
      await preferences.remove(currentLocationIdKey);
    }
    if (warehouseId != null) {
      await preferences.setInt(currentWarehouseIdKey, warehouseId);
    } else {
      await preferences.remove(currentWarehouseIdKey);
    }
    if (financialYearId != null) {
      await preferences.setInt(currentFinancialYearIdKey, financialYearId);
    } else {
      await preferences.remove(currentFinancialYearIdKey);
    }
  }

  static Future<int?> getCurrentCompanyId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(currentCompanyIdKey);
  }

  static Future<int?> getCurrentBranchId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(currentBranchIdKey);
  }

  static Future<int?> getCurrentLocationId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(currentLocationIdKey);
  }

  static Future<int?> getCurrentWarehouseId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(currentWarehouseIdKey);
  }

  static Future<int?> getCurrentFinancialYearId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(currentFinancialYearIdKey);
  }

  static Future<void> saveBranding(PublicBrandingModel branding) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      publicBrandingKey,
      jsonEncode(branding.toJson()),
    );
  }

  static Future<void> saveAuthContext(AuthContextModel context) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(authContextKey, jsonEncode(context.toJson()));
    await preferences.setStringList(
      permissionCodesKey,
      context.permissionCodes,
    );
  }

  static Future<AuthContextModel?> getAuthContext() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(authContextKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return AuthContextModel.fromJson(decoded);
  }

  static Future<List<String>> getPermissionCodes() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(permissionCodesKey) ?? const <String>[];
  }

  static Future<bool> isMasterDataCacheEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(masterDataCacheEnabledKey) ?? true;
  }

  static Future<void> setMasterDataCacheEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(masterDataCacheEnabledKey, value);
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
    await preferences.remove(currentWarehouseIdKey);
    await preferences.remove(currentFinancialYearIdKey);
    await preferences.remove(authContextKey);
    await preferences.remove(permissionCodesKey);
  }

  static Future<void> clear() async {
    await clearSessionOnly();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(publicBrandingKey);
  }
}
