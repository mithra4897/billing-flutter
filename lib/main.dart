import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/constants/app_config.dart';
import 'app/navigation/app_navigation.dart';
import 'app/theme/app_theme.dart';
import 'core/navigation/app_route_state.dart';
import 'view/auth/login_page.dart';
import 'view/core/app_bootstrap_page.dart';
import 'view/core/app_shell_page.dart';

void main() {
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(const BillingApp());
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  String _initialRouteName() {
    final uri = Uri.base;
    final path = uri.path.trim().isEmpty ? '/' : uri.path;
    if (path == '/' && uri.queryParameters.isEmpty) {
      return '/';
    }
    return Uri(
      path: path,
      queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: AppConfig.appTitle,
      theme: AppTheme.light(),
      initialRoute: _initialRouteName(),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        AppRouteState.update(uri.toString());

        switch (uri.path) {
          case '/':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const AppBootstrapPage(),
            );
          case '/login':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  LoginPage(redirectTo: uri.queryParameters['redirect']),
            );
          default:
            final matchedRoute =
                uri.path == '/dashboard' ||
                uri.path.startsWith('/purchase/') ||
                uri.path.startsWith('/sales/') ||
                AppNavigation.findByPath(uri.path) != null ||
                const <String>{
                  '/communication/send-email',
                  '/parties/addresses',
                  '/parties/contacts',
                  '/parties/gst-details',
                  '/parties/bank-accounts',
                  '/parties/credit-limits',
                  '/parties/payment-terms',
                }.contains(uri.path);
            if (matchedRoute) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => AppShellPage(
                  path: uri.path,
                  queryParameters: uri.queryParameters,
                ),
              );
            }

            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const LoginPage(),
            );
        }
      },
    );
  }
}
