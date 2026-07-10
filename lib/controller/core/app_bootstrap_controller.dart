import '../../screen.dart';

class AppBootstrapController extends GetxController {
  AppBootstrapController({required this.redirectTo});

  final PublicBrandingService _brandingService = PublicBrandingService();
  final AuthService _authService = AuthService();

  final String redirectTo;

  bool isLoading = true;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    bootstrap();
  }

  Future<void> bootstrap() async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      await _brandingService.fetchBranding();
      final restoredSession = await AppSessionService.instance.bootstrap(
        requireRememberMe: true,
      );

      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        _showError('Unable to start the application right now.');
        return;
      }

      if (!restoredSession) {
        _scheduleNavigation(() {
          if (navigator.mounted) {
            navigator.pushReplacementNamed(loginRoute());
          }
        });
        return;
      }

      _scheduleNavigation(() {
        if (navigator.mounted) {
          navigator.pushReplacementNamed(redirectTo);
        }
      });
      unawaited(_refreshSessionInBackground());
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to start the application right now.');
    }
  }

  Future<void> _refreshSessionInBackground() async {
    try {
      final me = await _authService.me();
      if (me.success && me.data != null) {
        await AppSessionService.instance.updateCurrentUser(me.data!);
      }
      await AppSessionService.instance.refreshUserAccess();
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await AppSessionService.instance.clearSession();
      }
    } catch (_) {}
  }

  String loginRoute() {
    return Uri(
      path: '/login',
      queryParameters: <String, String>{'redirect': redirectTo},
    ).toString();
  }

  void _showError(String message) {
    isLoading = false;
    errorMessage = message;
    update();
  }

  void _scheduleNavigation(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
      action();
    });
  }
}
