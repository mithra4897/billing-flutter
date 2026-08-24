import '../../controller/auth/reset_password_management_controller.dart';
import '../../screen.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.login, this.redirectTo});

  final String login;
  final String? redirectTo;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ResetPasswordManagementController',
      scope: <String, Object?>{
        'widget': widget.runtimeType,
        'key': widget.key,
        'state': identityHashCode(this),
        'login': widget.login,
        'redirectTo': widget.redirectTo,
      },
    );
    Get.put(
      ResetPasswordManagementController(
        login: widget.login,
        redirectTo: widget.redirectTo,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ResetPasswordManagementController>(
      tag: _controllerTag,
    )) {
      Get.delete<ResetPasswordManagementController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed(
      Uri(
        path: '/login',
        queryParameters: widget.redirectTo == null
            ? null
            : <String, String>{'redirect': widget.redirectTo!},
      ).toString(),
    );
  }

  String? _validatePassword(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) {
      return 'New password is required';
    }
    if (trimmed.length < 6) {
      return 'New password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(
    String? value,
    ResetPasswordManagementController controller,
  ) {
    if ((value ?? '').isEmpty) {
      return 'Confirm password is required';
    }
    if (value != controller.passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.login.trim().isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppErrorStateView(
                  title: 'Invalid Password Reset Request',
                  message: 'Please request a new password reset OTP.',
                  onRetry: _goToLogin,
                  actionLabel: 'Back to sign in',
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GetBuilder<ResetPasswordManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final message = controller.consumeActionMessage();
        if (message != null && message.trim().isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showMessage(message);
            }
          });
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final appTheme = theme.extension<AppThemeExtension>()!;
        final branding =
            controller.branding ??
            const PublicBrandingModel(companyName: 'Billing ERP');
        final year = branding.currentYear ?? DateTime.now().year;
        final width = MediaQuery.of(context).size.width;
        final showSidePanel = width >= 900;

        if (controller.isBootstrapping) {
          return Scaffold(
            body: AppLoadingView(message: 'Loading ${branding.companyName}...'),
          );
        }

        if (controller.brandingErrorMessage != null &&
            controller.branding == null) {
          return Scaffold(
            body: AppErrorStateView(
              title: 'Server Unavailable',
              message: controller.brandingErrorMessage!,
              onRetry: controller.loadBranding,
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                Expanded(
                  flex: showSidePanel ? 11 : 1,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppUiConstants.formMaxWidth,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(
                            AppUiConstants.cardPadding,
                          ),
                          decoration: BoxDecoration(
                            color: appTheme.cardBackground,
                            borderRadius: BorderRadius.circular(
                              AppUiConstants.cardRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: appTheme.cardShadow,
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            child: Builder(
                              builder: (formContext) => Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppBrandingLogo(branding: branding, size: 48),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Reset password',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.resetCompleted
                                        ? 'Your password has been updated. You can sign in with the new password now.'
                                        : 'Create a new password for your account.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: appTheme.mutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  if (!controller.resetCompleted) ...[
                                    AppTextField(
                                      label: 'Reset OTP',
                                      hint: 'Enter 6-digit OTP',
                                      icon: Icons.password_outlined,
                                      controller: controller.otpController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) =>
                                          RegExp(
                                            r'^\\d{6}$',
                                          ).hasMatch((value ?? '').trim())
                                          ? null
                                          : 'Enter the 6-digit OTP sent to your email',
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      label: 'New password',
                                      hint: 'Enter new password',
                                      icon: Icons.lock_outline,
                                      controller: controller.passwordController,
                                      obscureText: controller.obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      validator: _validatePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          controller.obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed:
                                            controller.togglePasswordVisibility,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      label: 'Confirm password',
                                      hint: 'Confirm new password',
                                      icon: Icons.lock_outline,
                                      controller:
                                          controller.confirmPasswordController,
                                      obscureText:
                                          controller.obscureConfirmPassword,
                                      textInputAction: TextInputAction.done,
                                      validator: (value) =>
                                          _validateConfirmPassword(
                                            value,
                                            controller,
                                          ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          controller.obscureConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: controller
                                            .toggleConfirmPasswordVisibility,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: controller.isLoading
                                            ? null
                                            : () async {
                                                final success = await controller
                                                    .submitReset(formContext);
                                                if (!context.mounted ||
                                                    !success) {
                                                  return;
                                                }
                                                FocusManager
                                                    .instance
                                                    .primaryFocus
                                                    ?.unfocus();
                                              },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppUiConstants.buttonRadius,
                                            ),
                                          ),
                                        ),
                                        child: controller.isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text('Update password'),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: appTheme.heroOverlayBackground,
                                        borderRadius: BorderRadius.circular(
                                          AppUiConstants.panelRadius,
                                        ),
                                        border: Border.all(
                                          color: appTheme.heroOverlayBorder,
                                        ),
                                      ),
                                      child: Text(
                                        'Password reset completed successfully. Use your new password on the sign-in screen.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(height: 1.5),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _goToLogin,
                                      child: const Text('Back to sign in'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Copyright $year ${branding.companyName}',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: appTheme.mutedText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showSidePanel)
                  Expanded(
                    flex: 9,
                    child: Container(
                      padding: const EdgeInsets.all(
                        AppUiConstants.pagePaddingLarge,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            appTheme.heroGradientStart,
                            appTheme.heroGradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppBrandingLogo(
                            branding: branding,
                            size: 56,
                            textColor: Colors.white,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Finish password recovery',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter the six-digit OTP from your email, then choose a new password.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.9,
                              ),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: appTheme.heroOverlayBackground,
                              borderRadius: BorderRadius.circular(
                                AppUiConstants.panelRadius,
                              ),
                              border: Border.all(
                                color: appTheme.heroOverlayBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                _ResetPasswordBullet(
                                  text: 'Accepts six-digit OTP from email',
                                ),
                                _ResetPasswordBullet(
                                  text:
                                      'Requires new password and confirmation',
                                ),
                                _ResetPasswordBullet(
                                  text:
                                      'Handles invalid or expired token responses',
                                ),
                                _ResetPasswordBullet(
                                  text: 'Returns cleanly to the sign-in page',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResetPasswordBullet extends StatelessWidget {
  const _ResetPasswordBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
