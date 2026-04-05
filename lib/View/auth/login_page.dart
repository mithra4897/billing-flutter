import 'package:flutter/material.dart';

import '../../components/app_branding_logo.dart';
import '../../components/app_loading_view.dart';
import '../../core/error/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../helper/validators.dart';
import '../../model/app/public_branding_model.dart';
import '../../model/auth/login_request_model.dart';
import '../../service/app/app_session_service.dart';
import '../../service/app/public_branding_service.dart';
import '../../service/auth/auth_service.dart';
import 'widgets/app_text_field.dart';

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
        });
      }
    } catch (_) {}

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
      _showMessage(error.message);
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
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF52606D)),
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
                                  backgroundColor: const Color(0xFF0A2540),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
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
                  padding: const EdgeInsets.all(48),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A2540), Color(0xFF184E77)],
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
