import '../../screen.dart';
import '../dashboard/dashboard_page.dart';
import '../parties/party_management_page.dart';
import '../settings/communication/email_messages_page.dart';
import '../settings/communication/email_module_settings_page.dart';
import '../settings/communication/email_rules_page.dart';
import '../settings/communication/email_settings_page.dart';
import '../settings/communication/email_templates_page.dart';
import '../settings/user/login_history_page.dart';
import '../settings/user/profile_page.dart';
import '../settings/user/role_management_page.dart';
import '../settings/user/user_management_page.dart';
import '../settings/master/branch_page.dart';
import '../settings/master/business_location_page.dart';
import '../settings/master/company_page.dart';
import '../settings/master/document_series_page.dart';
import '../settings/master/item_category_page.dart';
import '../settings/master/tax_category_page.dart';
import '../settings/master/uom_conversion_page.dart';
import '../settings/master/uom_page.dart';
import '../settings/master/warehouse_page.dart';
import '../settings/tax/gst_registration_page.dart';
import '../settings/tax/gst_tax_rule_page.dart';
import '../settings/tax/state_page.dart';
import '../settings/user/module_preferences_page.dart';
import 'module_placeholder_page.dart';

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
      case '/settings/document-series':
        return DocumentSeriesManagementPage(key: routeKey, embedded: true);
      case '/settings/module-preferences':
        return ModulePreferencesPage(key: routeKey, embedded: true);
      case '/inventory/uoms':
        return UomManagementPage(key: routeKey, embedded: true);
      case '/inventory/uom-conversions':
        return UomConversionManagementPage(key: routeKey, embedded: true);
      case '/inventory/tax-codes':
        return TaxCategoryManagementPage(key: routeKey, embedded: true);
      case '/inventory/item-categories':
        return ItemCategoryManagementPage(key: routeKey, embedded: true);
      case '/tax/states':
        return StateManagementPage(key: routeKey, embedded: true);
      case '/tax/gst-registrations':
        return GstRegistrationManagementPage(key: routeKey, embedded: true);
      case '/tax/gst-tax-rules':
        return GstTaxRuleManagementPage(key: routeKey, embedded: true);
      case '/communication/email-settings':
        return EmailSettingsPage(key: routeKey, embedded: true);
      case '/communication/email-module-settings':
        return EmailModuleSettingsPage(key: routeKey, embedded: true);
      case '/communication/email-templates':
        return EmailTemplatesPage(key: routeKey, embedded: true);
      case '/communication/email-rules':
        return EmailRulesPage(key: routeKey, embedded: true);
      case '/communication/email-messages':
      case '/communication/send-email':
        return EmailMessagesPage(key: routeKey, embedded: true);
      case '/parties':
        return PartyManagementPage(key: routeKey, embedded: true);
      case '/parties/addresses':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 1,
        );
      case '/parties/contacts':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 2,
        );
      case '/parties/gst-details':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 3,
        );
      case '/parties/bank-accounts':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 4,
        );
      case '/parties/credit-limits':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 5,
        );
      case '/parties/payment-terms':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 6,
        );
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
    final navigationTitle = AppNavigation.findByPath(path)?.title.trim();
    if ((navigationTitle ?? '').isNotEmpty) {
      return navigationTitle!;
    }

    for (final module in authContext?.menuModules ?? const []) {
      final routePath = module.routePath?.trim();
      final moduleName = module.moduleName?.trim();
      if (routePath == path && (moduleName ?? '').isNotEmpty) {
        return moduleName!;
      }
    }

    if (path.startsWith('/parties/')) {
      return 'Parties';
    }
    if (path == '/communication/send-email') {
      return 'Email Messages';
    }

    return 'Module';
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
