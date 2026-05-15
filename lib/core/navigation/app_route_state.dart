class AppRouteState {
  const AppRouteState._();

  static String _currentRoute = '/';
  static final List<String> _backHistory = <String>[];
  static final List<String> _forwardHistory = <String>[];
  static bool _redirectingToLogin = false;

  static String get currentRoute => _currentRoute;
  static String get previousRoute =>
      _backHistory.isEmpty ? '' : _backHistory.last;
  static String get nextRoute =>
      _forwardHistory.isEmpty ? '' : _forwardHistory.last;
  static bool get canGoBack => _backHistory.isNotEmpty;
  static bool get canGoForward => _forwardHistory.isNotEmpty;

  static bool get redirectingToLogin => _redirectingToLogin;

  static void update(String route) {
    final trimmed = route.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (trimmed == _currentRoute) {
      return;
    }
    if (_currentRoute.trim().isNotEmpty) {
      _backHistory.add(_currentRoute);
    }
    _forwardHistory.clear();
    _currentRoute = trimmed;
  }

  static String? goBack() {
    if (_backHistory.isEmpty) {
      return null;
    }
    _forwardHistory.add(_currentRoute);
    _currentRoute = _backHistory.removeLast();
    return _currentRoute;
  }

  static String? goForward() {
    if (_forwardHistory.isEmpty) {
      return null;
    }
    _backHistory.add(_currentRoute);
    _currentRoute = _forwardHistory.removeLast();
    return _currentRoute;
  }

  static void setRedirectingToLogin(bool value) {
    _redirectingToLogin = value;
  }
}
