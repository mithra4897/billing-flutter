import '../../screen.dart';

class AppShellController extends GetxController {
  AppShellController({
    required String initialPath,
    required Map<String, String> initialQueryParameters,
  }) : currentPath = initialPath,
       currentQueryParameters = Map<String, String>.from(
         initialQueryParameters,
       );

  PublicBrandingModel branding = const PublicBrandingModel(
    companyName: 'Billing ERP',
  );
  AuthContextModel? authContext;
  bool isCheckingSession = true;
  String currentPath;
  Map<String, String> currentQueryParameters;
  final ShellPageActionsController shellPageActionsController =
      ShellPageActionsController();
  int contextVersion = 0;

  @override
  void onInit() {
    super.onInit();
    AppSessionService.accessVersion.addListener(_handleAccessVersionChanged);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
    unawaited(bootstrapShell());
  }

  @override
  void onClose() {
    AppSessionService.accessVersion.removeListener(_handleAccessVersionChanged);
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    shellPageActionsController.dispose();
    super.onClose();
  }

  void syncRouteInputs({
    required String path,
    required Map<String, String> queryParameters,
    bool notify = true,
  }) {
    currentPath = path;
    currentQueryParameters = Map<String, String>.from(queryParameters);
    if (notify) {
      update();
    }
  }

  Future<void> loadShellContext() async {
    final nextBranding = await SessionStorage.getBranding();
    final nextAuthContext = await SessionStorage.getAuthContext();
    final permissionCodes = await SessionStorage.getPermissionCodes();
    final currentUser = await SessionStorage.getCurrentUser();

    branding = nextBranding ?? branding;
    authContext = nextAuthContext;
    update();

    ensureCurrentRouteAllowed(
      permissionCodes: permissionCodes.toSet(),
      isSuperAdmin:
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1,
      orderedModules: nextAuthContext?.menuModules ?? const <ModuleModel>[],
    );
  }

  Future<void> bootstrapShell() async {
    final hasSession = await AppSessionService.instance.bootstrap();

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      isCheckingSession = false;
      update();
      return;
    }

    if (!hasSession) {
      _scheduleNavigation(() {
        if (navigator.mounted) {
          navigator.pushNamedAndRemoveUntil(loginRoute(), (_) => false);
        }
      });
      return;
    }

    await loadShellContext();
    isCheckingSession = false;
    update();

    unawaited(refreshShellContextInBackground());
  }

  Future<void> refreshShellContextInBackground() async {
    try {
      await AppSessionService.instance.refreshUserAccess();
    } catch (_) {}
  }

  String loginRoute() {
    final redirectTo = Uri(
      path: currentPath,
      queryParameters: currentQueryParameters.isEmpty
          ? null
          : currentQueryParameters,
    ).toString();

    return Uri(
      path: '/login',
      queryParameters: <String, String>{'redirect': redirectTo},
    ).toString();
  }

  void handleNavigate(String route) {
    final uri = Uri.parse(route);
    FocusManager.instance.primaryFocus?.unfocus();
    shellPageActionsController.clearActions();
    currentPath = uri.path;
    currentQueryParameters = Map<String, String>.from(uri.queryParameters);
    AppRouteState.update(uri.toString());
    SystemNavigator.routeInformationUpdated(uri: uri, replace: true);
    update();
  }

  void _handleAccessVersionChanged() {
    unawaited(loadShellContext());
  }

  void _handleWorkingContextChanged() {
    contextVersion = WorkingContextService.version.value;
    update();
  }

  void _scheduleNavigation(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
      action();
    });
  }

  void ensureCurrentRouteAllowed({
    required Set<String> permissionCodes,
    required bool isSuperAdmin,
    required List<ModuleModel> orderedModules,
  }) {
    return;
  }
}
