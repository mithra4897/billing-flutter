import '../../controller/core/app_bootstrap_controller.dart';
import '../../screen.dart';

class AppBootstrapPage extends StatefulWidget {
  const AppBootstrapPage({super.key, this.redirectTo = '/dashboard'});

  final String redirectTo;

  @override
  State<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends State<AppBootstrapPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('AppBootstrapController');
    if (Get.isRegistered<AppBootstrapController>(tag: _controllerTag)) {
      Get.delete<AppBootstrapController>(tag: _controllerTag, force: true);
    }
    Get.put(
      AppBootstrapController(redirectTo: widget.redirectTo),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<AppBootstrapController>(tag: _controllerTag)) {
      Get.delete<AppBootstrapController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppBootstrapController>(
      tag: _controllerTag,
      builder: (controller) {
        return Scaffold(
          body: controller.isLoading
              ? const AppLoadingView(message: 'Starting application...')
              : controller.errorMessage != null
              ? AppErrorStateView(
                  title: 'Server Unavailable',
                  message: controller.errorMessage!,
                  onRetry: controller.bootstrap,
                )
              : const AppLoadingView(message: 'Starting application...'),
        );
      },
    );
  }
}
