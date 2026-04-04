import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  static const String appTitle = 'Billing ERP';
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  static const String apiPrefix = '/api/v1';
  static const String loginEndpoint = '$apiPrefix/auth/login';

  static const String accessTokenKey = 'access_token';
  static const String tokenTypeKey = 'token_type';
  static const String expiresInKey = 'expires_in';
}
