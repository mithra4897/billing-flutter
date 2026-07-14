import '../../controller/auth/forgot_password_management_controller.dart';
import '../../screen.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ForgotPasswordManagementController',
      scope: <String, Object?>{
        'widget': widget.runtimeType,
        'key': widget.key,
        'state': identityHashCode(this),
        'redirectTo': widget.redirectTo,
      },
    );
    Get.put(
      ForgotPasswordManagementController(redirectTo: widget.redirectTo),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ForgotPasswordManagementController>(
      tag: _controllerTag,
    )) {
      Get.delete<ForgotPasswordManagementController>(
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

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ForgotPasswordManagementController>(
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
                                    'Forgot password',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.requestSent
                                        ? 'If the account exists and email delivery is available, reset instructions will be sent to the registered email address.'
                                        : 'Enter your email or user ID and we will submit a password reset request.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: appTheme.mutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  if (!controller.requestSent) ...[
                                    AppTextField(
                                      label: 'Email or ID',
                                      hint: 'Enter email or ID',
                                      icon: Icons.person_outline,
                                      controller: controller.loginController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      validator: (value) =>
                                          Validators.requiredField(
                                            value,
                                            'Email or ID',
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
                                                await controller.submitRequest(
                                                  formContext,
                                                );
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
                                            : const Text(
                                                'Send reset instructions',
                                              ),
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
                                        'We have accepted the request. If the account exists, the reset link will be sent from the configured company email setting to the employee email linked with that user.',
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
                            'Secure password recovery',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This screen is ready for a public reset flow. Connect it to the backend endpoint and keep the response generic so account existence is never exposed.',
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
                                _ForgotPasswordBullet(
                                  text:
                                      'Public route available at /forgot-password',
                                ),
                                _ForgotPasswordBullet(
                                  text:
                                      'Accepts email or user ID as the identifier',
                                ),
                                _ForgotPasswordBullet(
                                  text:
                                      'Neutral success messaging prevents user enumeration',
                                ),
                                _ForgotPasswordBullet(
                                  text:
                                      'Returns cleanly back to the sign-in page',
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

class _ForgotPasswordBullet extends StatelessWidget {
  const _ForgotPasswordBullet({required this.text});

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
