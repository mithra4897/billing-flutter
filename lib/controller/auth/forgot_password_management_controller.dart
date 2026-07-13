import '../../screen.dart';

class ForgotPasswordManagementController extends GetxController {
  ForgotPasswordManagementController({required this.redirectTo});

  final String? redirectTo;

  final TextEditingController loginController = TextEditingController();

  final AuthService _authService = AuthService();
  final PublicBrandingService _brandingService = PublicBrandingService();

  PublicBrandingModel? branding;
  bool isLoading = false;
  bool isBootstrapping = true;
  bool requestSent = false;
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

  Future<bool> submitRequest(BuildContext formContext) async {
    if (Form.of(formContext).validate() != true) {
      return false;
    }

    isLoading = true;
    update();

    try {
      final response = await _authService.forgotPassword(
        ForgotPasswordRequestModel(
          login: loginController.text.trim(),
          resetUrl: Uri.base.resolve('/reset-password').toString(),
        ),
      );

      if (response.success) {
        requestSent = true;
        actionMessage = response.message.trim().isEmpty
            ? 'If the account exists, reset instructions have been sent.'
            : response.message;
        return true;
      }

      actionMessage = response.message.trim().isEmpty
          ? 'Unable to submit the reset request right now.'
          : response.message;
      return false;
    } on ApiException catch (errorValue) {
      if (errorValue.isConnectivityIssue) {
        actionMessage = 'Server is unreachable right now. Please try again.';
      } else if (errorValue.statusCode == 404 ||
          errorValue.statusCode == 405 ||
          errorValue.statusCode == 501) {
        actionMessage =
            'Forgot password is not enabled on the server yet. Please add the /auth/forgot-password backend endpoint.';
      } else if (errorValue.message.trim() == 'Request failed') {
        actionMessage =
            'Forgot password request could not be completed. Please verify the backend endpoint and response payload.';
      } else {
        actionMessage = errorValue.message;
      }
      return false;
    } catch (_) {
      actionMessage = 'Unable to submit the reset request right now.';
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }
}
