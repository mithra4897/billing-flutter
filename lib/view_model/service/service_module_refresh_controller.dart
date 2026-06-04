import '../../../screen.dart';

class ServiceModuleRefreshEvent {
  const ServiceModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class ServiceModuleRefreshController extends GetxController {
  static const String tag = 'ServiceModuleRefreshController';

  final Rxn<ServiceModuleRefreshEvent> lastEvent =
      Rxn<ServiceModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = ServiceModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static ServiceModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<ServiceModuleRefreshController>(tag: tag)) {
      return Get.find<ServiceModuleRefreshController>(tag: tag);
    }
    return Get.put(ServiceModuleRefreshController(), tag: tag, permanent: true);
  }
}
