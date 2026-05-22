import '../../screen.dart';

class LoginManagementController extends GetxController {
  LoginManagementController({required this.redirectTo});

  final String? redirectTo;

  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final PublicBrandingService _brandingService = PublicBrandingService();

  PublicBrandingModel? branding;
  bool obscurePassword = true;
  bool rememberMe = false;
  bool isLoading = false;
  bool isBootstrapping = true;
  String? brandingErrorMessage;
  String? actionMessage;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadBranding());
  }

  @override
  void onClose() {
    loginController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  Future<void> loadBranding() async {
    final cached = await SessionStorage.getBranding();
    branding = cached;
    update();

    try {
      final response = await _brandingService.fetchBranding();
      if (response.success && response.data != null) {
        branding = response.data;
        brandingErrorMessage = null;
      }
    } on ApiException catch (errorValue) {
      if (cached == null) {
        brandingErrorMessage = errorValue.message;
      }
    } catch (_) {
      if (cached == null) {
        brandingErrorMessage = 'Unable to reach the server right now.';
      }
    }

    isBootstrapping = false;
    update();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    update();
  }

  void setRememberMe(bool value) {
    rememberMe = value;
    update();
  }

  Future<bool> signIn(BuildContext formContext) async {
    if (Form.of(formContext).validate() != true) {
      return false;
    }

    isLoading = true;
    update();

    try {
      final response = await _authService.login(
        LoginRequestModel(
          login: loginController.text.trim(),
          password: passwordController.text,
        ),
      );

      if (response.success && response.data != null) {
        await AppSessionService.instance.handleLoginSession(
          response.data!,
          rememberMe: rememberMe,
        );
        return true;
      }

      actionMessage = response.message.isEmpty
          ? 'Login failed'
          : response.message;
      return false;
    } on ApiException catch (errorValue) {
      actionMessage = errorValue.isConnectivityIssue
          ? 'Server is unreachable right now. Please try again.'
          : errorValue.message;
      return false;
    } catch (_) {
      actionMessage = 'Unable to sign in right now.';
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }
}
