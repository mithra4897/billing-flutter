import '../../screen.dart';

class AppSessionService {
  AppSessionService._();

  static final AppSessionService instance = AppSessionService._();
  static final ValueNotifier<int> accessVersion = ValueNotifier<int>(0);

  final AuthService _authService = AuthService();
  Timer? _refreshTimer;
  Future<void>? _clearSessionFuture;
  bool _sessionEnding = false;

  bool get isSessionEnding => _sessionEnding;

  Future<void> handleLoginSession(
    LoginResponseModel session, {
    required bool rememberMe,
  }) async {
    final pendingClear = _clearSessionFuture;
    if (pendingClear != null) {
      await pendingClear;
    }
    _clearSessionFuture = null;
    _sessionEnding = false;
    advancePersistentControllerSessionScope();
    await SessionStorage.saveSession(
      token: session.accessToken,
      tokenType: session.tokenType,
      expiresIn: session.expiresIn,
      currentUser: session.user?.toJson(),
      rememberMe: rememberMe,
    );
    await refreshUserAccess();
    await _scheduleRefresh();
  }

  Future<bool> bootstrap({bool requireRememberMe = false}) async {
    final hasSession = requireRememberMe
        ? await SessionStorage.hasRestorableSession()
        : await SessionStorage.hasActiveSession();
    if (!hasSession) {
      await clearSession();
      return false;
    }

    await _scheduleRefresh();
    return true;
  }

  Future<void> clearSession() async {
    final inProgress = _clearSessionFuture;
    if (inProgress != null) {
      return inProgress;
    }

    _sessionEnding = true;
    final future = _clearSessionImpl();
    _clearSessionFuture = future;
    return future;
  }

  Future<void> logout() async {
    _sessionEnding = true;
    if (Get.isRegistered<MasterDataCache>()) {
      MasterDataCache.to.clearAllCaches();
    } else {
      ApiCacheStore.clear();
    }

    try {
      await _authService.logout();
    } catch (_) {
    } finally {
      await clearSession();
    }
  }

  Future<void> _clearSessionImpl() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    advancePersistentControllerSessionScope();
    if (Get.isRegistered<MasterDataCache>()) {
      MasterDataCache.to.clearAllCaches();
    } else {
      ApiCacheStore.clear();
    }
    await SessionStorage.clearSessionOnly();
    accessVersion.value++;
  }

  Future<void> _scheduleRefresh() async {
    _refreshTimer?.cancel();
    final expiresAt = await SessionStorage.getExpiresAt();
    if (expiresAt == null) {
      return;
    }

    final refreshAt = expiresAt.subtract(const Duration(seconds: 60));
    var delay = refreshAt.difference(DateTime.now());
    if (delay.isNegative) {
      delay = const Duration(seconds: 5);
    }

    _refreshTimer = Timer(delay, () async {
      await refreshToken();
    });
  }

  Future<bool> refreshToken() async {
    try {
      final response = await _authService.refresh();
      final refreshed = response.data;

      if (!response.success ||
          refreshed == null ||
          refreshed.accessToken.isEmpty) {
        await clearSession();
        return false;
      }

      await SessionStorage.saveSession(
        token: refreshed.accessToken,
        tokenType: refreshed.tokenType,
        expiresIn: refreshed.expiresIn,
        currentUser: (await SessionStorage.getCurrentUser()),
        rememberMe: await SessionStorage.shouldAutoLogin(),
      );
      // Conditional-response entries are scoped to the previous access token.
      // Remove them immediately so refreshed sessions do not retain sensitive
      // response bodies or unreachable cache keys.
      ApiCacheStore.clear();
      await _scheduleRefresh();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await clearSession();
        return false;
      }

      if (error.isConnectivityIssue) {
        _scheduleRetry(const Duration(seconds: 30));
        return false;
      }

      await clearSession();
      return false;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> refreshUserAccess() async {
    try {
      final profileResponse = await _authService.profile();
      if (profileResponse.success && profileResponse.data != null) {
        await SessionStorage.saveCurrentUser(profileResponse.data!.toJson());
      }

      final contextResponse = await _authService.context();
      if (contextResponse.success && contextResponse.data != null) {
        if (Get.isRegistered<MasterDataCache>()) {
          MasterDataCache.to.clearAllCaches();
        } else {
          ApiCacheStore.clear();
        }
        await SessionStorage.saveAuthContext(contextResponse.data!);
        final context = contextResponse.data!;
        await WorkingContextService.instance.resolveSelection(
          companies: context.companies,
          branches: context.branches,
          locations: context.locations,
          warehouses: context.warehouses,
          financialYears: context.financialYears,
        );
        accessVersion.value++;
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await clearSession();
      }
    } catch (_) {}
  }

  Future<void> updateCurrentUser(AuthUserModel user) async {
    await SessionStorage.saveCurrentUser(user.toJson());
    accessVersion.value++;
  }

  void _scheduleRetry(Duration delay) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () async {
      await refreshToken();
    });
  }
}
