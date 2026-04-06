import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/navigation/app_navigation.dart';
import '../../components/adaptive_shell.dart';
import '../../core/storage/session_storage.dart';
import '../../model/app/public_branding_model.dart';
import '../../model/auth/auth_context_model.dart';
import '../../service/app/app_session_service.dart';
import '../dashboard/dashboard_page.dart';
import '../settings/user/login_history_page.dart';
import '../settings/user/profile_page.dart';
import '../settings/user/role_management_page.dart';
import '../settings/user/user_management_page.dart';
import '../settings/master/master_setup_pages.dart';
import 'module_placeholder_page.dart';
import 'page_shell_actions.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    required this.path,
    this.queryParameters = const <String, String>{},
  });

  final String path;
  final Map<String, String> queryParameters;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  PublicBrandingModel _branding = const PublicBrandingModel(
    companyName: 'Billing ERP',
  );
  AuthContextModel? _authContext;
  late String _currentPath;
  late Map<String, String> _currentQueryParameters;
  late final ShellPageActionsController _shellPageActionsController;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.path;
    _currentQueryParameters = Map<String, String>.from(widget.queryParameters);
    _shellPageActionsController = ShellPageActionsController();
    _loadShellContext();
  }

  @override
  void dispose() {
    _shellPageActionsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        !_sameQuery(oldWidget.queryParameters, widget.queryParameters)) {
      _currentPath = widget.path;
      _currentQueryParameters = Map<String, String>.from(
        widget.queryParameters,
      );
    }
  }

  Future<void> _loadShellContext() async {
    final branding = await SessionStorage.getBranding();
    final authContext = await SessionStorage.getAuthContext();
    if (!mounted) {
      return;
    }

    setState(() {
      _branding = branding ?? _branding;
      _authContext = authContext;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await AppSessionService.instance.clearSession();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  void _handleNavigate(String route) {
    final uri = Uri.parse(route);
    _shellPageActionsController.clearActions();
    setState(() {
      _currentPath = uri.path;
      _currentQueryParameters = Map<String, String>.from(uri.queryParameters);
    });

    SystemNavigator.routeInformationUpdated(uri: uri, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveShell(
      title: _titleForPath(_currentPath, _authContext),
      branding: _branding,
      currentPath: _buildCurrentRoute(),
      actionsListenable: _shellPageActionsController,
      onNavigate: _handleNavigate,
      onLogout: () => _logout(context),
      child: ShellPageActionsScope(
        controller: _shellPageActionsController,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          child: _buildContent(),
        ),
      ),
    );
  }

  String _buildCurrentRoute() {
    final uri = Uri(
      path: _currentPath,
      queryParameters: _currentQueryParameters.isEmpty
          ? null
          : _currentQueryParameters,
    );
    return uri.toString();
  }

  Widget _buildContent() {
    final routeKey = ValueKey<String>(_buildCurrentRoute());

    switch (_currentPath) {
      case '/dashboard':
        return DashboardPage(key: routeKey, embedded: true);
      case '/settings/profile':
        return ProfilePage(key: routeKey, embedded: true);
      case '/settings/users':
        return UserManagementPage(
          key: routeKey,
          embedded: true,
          initialUserId: int.tryParse(_currentQueryParameters['id'] ?? ''),
        );
      case '/settings/login-history':
        return LoginHistoryPage(key: routeKey, embedded: true);
      case '/settings/roles':
        return RoleManagementPage(
          key: routeKey,
          embedded: true,
          initialRoleId: int.tryParse(_currentQueryParameters['id'] ?? ''),
        );
      case '/settings/companies':
        return CompanyManagementPage(key: routeKey, embedded: true);
      case '/settings/branches':
        return BranchManagementPage(key: routeKey, embedded: true);
      case '/settings/business-locations':
        return BusinessLocationManagementPage(key: routeKey, embedded: true);
      case '/settings/warehouses':
        return WarehouseManagementPage(key: routeKey, embedded: true);
      default:
        return ModulePlaceholderPage(
          key: routeKey,
          embedded: true,
          path: _currentPath,
          queryParameters: _currentQueryParameters,
        );
    }
  }

  String _titleForPath(String path, AuthContextModel? authContext) {
    for (final module in authContext?.menuModules ?? const []) {
      final routePath = module.routePath?.trim();
      final moduleName = module.moduleName?.trim();
      if (routePath == path && (moduleName ?? '').isNotEmpty) {
        return moduleName!;
      }
    }

    return AppNavigation.findByPath(path)?.title ?? 'Module';
  }

  bool _sameQuery(Map<String, String> left, Map<String, String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}
