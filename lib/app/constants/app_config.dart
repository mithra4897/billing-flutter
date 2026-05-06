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

    return 'https://bill.sakthicontroller.com/api/public';
  }

  static String get apiBaseUrl => '$baseHost$apiPrefix';

  static String? resolvePublicFileUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final normalized = path.startsWith('/') ? path : '/$path';
    return '$baseHost$normalized';
  }
}
