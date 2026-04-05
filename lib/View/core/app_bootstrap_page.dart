import 'package:flutter/material.dart';

import '../../components/app_loading_view.dart';
import '../../core/storage/session_storage.dart';
import '../../service/app/app_session_service.dart';
import '../../service/app/public_branding_service.dart';
import '../../service/auth/auth_service.dart';

class AppBootstrapPage extends StatefulWidget {
  const AppBootstrapPage({super.key});

  @override
  State<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends State<AppBootstrapPage> {
  final PublicBrandingService _brandingService = PublicBrandingService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _brandingService.fetchBranding();
    await AppSessionService.instance.bootstrap();

    if (!mounted) {
      return;
    }

    final shouldAutoLogin = await SessionStorage.shouldAutoLogin();
    if (!mounted) {
      return;
    }
    if (!shouldAutoLogin) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final me = await _authService.me();
      if (!mounted) {
        return;
      }
      if (me.success) {
        if (me.data != null) {
          await AppSessionService.instance.updateCurrentUser(me.data!);
        }
        await AppSessionService.instance.refreshUserAccess();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return;
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppLoadingView(message: 'Starting application...'),
    );
  }
}
