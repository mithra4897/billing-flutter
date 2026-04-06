import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/constants/app_config.dart';
import 'app/navigation/app_navigation.dart';
import 'app/theme/app_theme.dart';
import 'view/auth/login_page.dart';
import 'view/core/app_bootstrap_page.dart';
import 'view/core/app_shell_page.dart';

void main() {
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(const BillingApp());
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appTitle,
      theme: AppTheme.light(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

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
