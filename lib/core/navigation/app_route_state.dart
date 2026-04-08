class AppRouteState {
  const AppRouteState._();

  static String _currentRoute = '/';
  static bool _redirectingToLogin = false;

  static String get currentRoute => _currentRoute;

  static bool get redirectingToLogin => _redirectingToLogin;

  static void update(String route) {
    final trimmed = route.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _currentRoute = trimmed;
  }

  static void setRedirectingToLogin(bool value) {
    _redirectingToLogin = value;
  }
}
