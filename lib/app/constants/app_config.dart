import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String appTitle = 'Billing ERP';
  static const String apiPrefix = '/api/v1';
  static const String publicBrandingEndpoint = '/public/branding';

  static String get baseHost {
    const configuredUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    // if (kIsWeb) {
    //   final current = Uri.base;
    //   final host = current.host;
    //   final scheme = current.scheme.isNotEmpty ? current.scheme : 'http';
    //
    //   if (host.isNotEmpty) {
    //     if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    //       return 'http://bill.local:8000';
    //     }
    //
    //     if (current.pathSegments.contains('billing') && current.port != 8000) {
    //       return '$scheme://$host:8000';
    //     }
    //
    //     if (current.port == 8000) {
    //       final origin = current.origin;
    //       if (origin.isNotEmpty) {
    //         return origin;
    //       }
    //     }
    //   }
    // }

    return 'http://192.168.31.83:8000';
    // return 'https://bill.sakthicontroller.com/api/public';
  }

  static String get apiBaseUrl => '$baseHost$apiPrefix';

  static String? resolvePublicFileUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final normalized = path.trim();
    if (normalized.startsWith('uploads/')) {
      return '$apiBaseUrl/public/media/file?path=${Uri.encodeComponent(normalized)}';
    }

    final normalizedPath = normalized.startsWith('/')
        ? normalized
        : '/$normalized';
    return '$baseHost$normalizedPath';
  }
}
