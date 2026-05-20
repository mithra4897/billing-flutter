import '../../screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _brandingService = PublicBrandingService();

  PublicBrandingModel? _branding;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isBootstrapping = true;
  String? _brandingErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBranding() async {
    final cached = await SessionStorage.getBranding();
    if (mounted) {
      setState(() {
        _branding = cached;
      });
    }

    try {
      final response = await _brandingService.fetchBranding();
      if (mounted && response.success && response.data != null) {
        setState(() {
          _branding = response.data;
          _brandingErrorMessage = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted && cached == null) {
        setState(() {
          _brandingErrorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted && cached == null) {
        setState(() {
          _brandingErrorMessage = 'Unable to reach the server right now.';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isBootstrapping = false;
      });
    }
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        LoginRequestModel(
          login: _loginController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      if (response.success && response.data != null) {
        await AppSessionService.instance.handleLoginSession(
          response.data!,
          rememberMe: _rememberMe,
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.redirectTo ?? '/dashboard',
          (_) => false,
        );
        return;
      }

      _showMessage(
        response.message.isEmpty ? 'Login failed' : response.message,
      );
    } on ApiException catch (error) {
      _showMessage(
        error.isConnectivityIssue
            ? 'Server is unreachable right now. Please try again.'
            : error.message,
      );
    } catch (_) {
      _showMessage('Unable to sign in right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = theme.extension<AppThemeExtension>()!;
    final branding =
        _branding ?? const PublicBrandingModel(companyName: 'Billing ERP');
    final year = branding.currentYear ?? DateTime.now().year;
    final width = MediaQuery.of(context).size.width;
    final showSidePanel = width >= 900;

    if (_isBootstrapping) {
      return Scaffold(
        body: AppLoadingView(message: 'Loading ${branding.companyName}...'),
      );
    }

    if (_brandingErrorMessage != null && _branding == null) {
      return Scaffold(
        body: AppErrorStateView(
          title: 'Server Unavailable',
          message: _brandingErrorMessage!,
          onRetry: _loadBranding,
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
                      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
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
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppBrandingLogo(branding: branding, size: 48),
                            const SizedBox(height: 18),
                            Text(
                              'Sign in',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Access your ERP workspace across mobile, tablet, desktop, and web.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: appTheme.mutedText,
                              ),
                            ),
                            const SizedBox(height: 28),
                            AppTextField(
                              label: 'Email or ID',
                              hint: 'Enter email or ID',
                              icon: Icons.person_outline,
                              controller: _loginController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  Validators.requiredField(value, 'Login'),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Password',
                              hint: 'Enter your password',
                              icon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              validator: (value) =>
                                  Validators.requiredField(value, 'Password'),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                      ),
                                      const Flexible(
                                        child: Text('Remember me'),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading ? null : () {},
                                  child: const Text('Forgot?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppUiConstants.buttonRadius,
                                    ),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sign in'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Copyright $year ${branding.companyName}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: appTheme.mutedText,
                                ),
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
                        'Unified ERP workspace',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Responsive by design for mobile, tablet, desktop, and web. Routing, session renewal, and branding are now shell-level concerns instead of screen-level hacks.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.9),
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
                          border: Border.all(color: appTheme.heroOverlayBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _BulletText(
                              'Route-based navigation for web and app',
                            ),
                            _BulletText('Persistent responsive drawer shell'),
                            _BulletText('Remember-me auto login support'),
                            _BulletText('Token renewal before expiry'),
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
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
