import '../../../screen.dart';

class JobworkModuleRefreshEvent {
  const JobworkModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class JobworkModuleRefreshController extends GetxController {
  static const String tag = 'JobworkModuleRefreshController';

  final Rxn<JobworkModuleRefreshEvent> lastEvent =
      Rxn<JobworkModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = JobworkModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static JobworkModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<JobworkModuleRefreshController>(tag: tag)) {
      return Get.find<JobworkModuleRefreshController>(tag: tag);
    }
    return Get.put(JobworkModuleRefreshController(), tag: tag, permanent: true);
  }
}
