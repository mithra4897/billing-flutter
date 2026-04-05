import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String appTitle = 'Billing ERP';
  static const String apiPrefix = '/api/v1';

  static String get baseHost {
    const configuredUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

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

  static String get apiBaseUrl => '$baseHost$apiPrefix';
}
