import '../../screen.dart';

class ResetPasswordManagementController extends GetxController {
  ResetPasswordManagementController({
    required this.token,
    required this.redirectTo,
  });

  final String token;
  final String? redirectTo;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();
  final PublicBrandingService _brandingService = PublicBrandingService();

  PublicBrandingModel? branding;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;
  bool isBootstrapping = true;
  bool resetCompleted = false;
  String? brandingErrorMessage;
  String? actionMessage;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadBranding());
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
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

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    update();
  }

  Future<bool> submitReset(BuildContext formContext) async {
    if (Form.of(formContext).validate() != true) {
      return false;
    }

    isLoading = true;
    update();

    try {
      final response = await _authService.resetPassword(
        PublicResetPasswordRequestModel(
          token: token,
          newPassword: passwordController.text,
          confirmPassword: confirmPasswordController.text,
        ),
      );

      if (response.success) {
        resetCompleted = true;
        actionMessage = response.message.trim().isEmpty
            ? 'Password reset successfully. You can sign in now.'
            : response.message;
        return true;
      }

      actionMessage = response.message.trim().isEmpty
          ? 'Unable to reset password right now.'
          : response.message;
      return false;
    } on ApiException catch (errorValue) {
      actionMessage = errorValue.isConnectivityIssue
          ? 'Server is unreachable right now. Please try again.'
          : errorValue.message;
      return false;
    } catch (_) {
      actionMessage = 'Unable to reset password right now.';
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }
}
