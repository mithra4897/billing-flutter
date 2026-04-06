import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/constants/app_config.dart';
import 'app/navigation/app_navigation.dart';
import 'app/theme/app_theme.dart';
import 'view/auth/login_page.dart';
import 'view/core/app_bootstrap_page.dart';
import 'view/core/module_placeholder_page.dart';
import 'view/dashboard/dashboard_page.dart';
import 'view/settings/user/login_history_page.dart';
import 'view/settings/user/profile_page.dart';
import 'view/settings/user/role_management_page.dart';
import 'view/settings/user/user_management_page.dart';

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
          case '/dashboard':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const DashboardPage(),
            );
          case '/login':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  LoginPage(redirectTo: uri.queryParameters['redirect']),
            );
          case '/settings/profile':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ProfilePage(),
            );
          case '/settings/users':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => UserManagementPage(
                initialUserId: int.tryParse(uri.queryParameters['id'] ?? ''),
              ),
            );
          case '/settings/login-history':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const LoginHistoryPage(),
            );
          case '/settings/roles':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => RoleManagementPage(
                initialRoleId: int.tryParse(uri.queryParameters['id'] ?? ''),
              ),
            );
          default:
            final matchedRoute = AppNavigation.findByPath(uri.path);
            if (matchedRoute != null) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => ModulePlaceholderPage(
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
