import '../../screen.dart';

class AppBootstrapPage extends StatefulWidget {
  const AppBootstrapPage({super.key});

  @override
  State<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends State<AppBootstrapPage> {
  final PublicBrandingService _brandingService = PublicBrandingService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
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
      } on ApiException catch (error) {
        if (error.isConnectivityIssue) {
          _showError(error.message);
          return;
        }
      } catch (_) {
        _showError('Unable to connect to the server right now.');
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed('/login');
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to start the application right now.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const AppLoadingView(message: 'Starting application...')
          : _errorMessage != null
          ? AppErrorStateView(
              title: 'Server Unavailable',
              message: _errorMessage!,
              onRetry: _bootstrap,
            )
          : const AppLoadingView(message: 'Starting application...'),
    );
  }
}
