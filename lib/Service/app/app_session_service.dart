import 'dart:async';

import '../../core/storage/session_storage.dart';
import '../../model/auth/login_response_model.dart';
import '../auth/auth_service.dart';

class AppSessionService {
  AppSessionService._();

  static final AppSessionService instance = AppSessionService._();

  final AuthService _authService = AuthService();
  Timer? _refreshTimer;

  Future<void> handleLoginSession(
    LoginResponseModel session, {
    required bool rememberMe,
  }) async {
    await SessionStorage.saveSession(
      token: session.accessToken,
      tokenType: session.tokenType,
      expiresIn: session.expiresIn,
      currentUser: session.user?.toJson(),
      rememberMe: rememberMe,
    );
    await _scheduleRefresh();
  }

  Future<void> bootstrap() async {
    if (!await SessionStorage.shouldAutoLogin()) {
      await clearSession();
      return;
    }

    await _scheduleRefresh();
  }

  Future<void> clearSession() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await SessionStorage.clearSessionOnly();
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
      await _scheduleRefresh();
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }
}
