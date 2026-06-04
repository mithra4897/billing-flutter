import 'package:get/get.dart';

class ProjectModuleRefreshEvent {
  const ProjectModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class ProjectModuleRefreshController extends GetxController {
  static const String tag = 'ProjectModuleRefreshController';

  final Rxn<ProjectModuleRefreshEvent> lastEvent =
      Rxn<ProjectModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    lastEvent.value = ProjectModuleRefreshEvent(
      sequence: ++_sequence,
      source: source,
    );
  }

  static ProjectModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<ProjectModuleRefreshController>(tag: tag)) {
      return Get.find<ProjectModuleRefreshController>(tag: tag);
    }
    return Get.put(ProjectModuleRefreshController(), tag: tag, permanent: true);
  }
}
