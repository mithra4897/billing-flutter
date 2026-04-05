import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/constants/app_config.dart';
import 'view/auth/login_page.dart';
import 'view/core/app_bootstrap_page.dart';
import 'view/dashboard/dashboard_page.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0A2540),
        scaffoldBackgroundColor: const Color(0xFFEFF3F6),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        switch (uri.path) {
          case '/':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const AppBootstrapPage(),
            );
          case '/dashboard':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const DashboardPage(),
            );
          case '/login':
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  LoginPage(redirectTo: uri.queryParameters['redirect']),
            );
        }
      },
    );
  }
}
