import '../../../screen.dart';

class MaintenanceModuleRefreshEvent {
  const MaintenanceModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class MaintenanceModuleRefreshController extends GetxController {
  static const String tag = 'MaintenanceModuleRefreshController';

  final Rxn<MaintenanceModuleRefreshEvent> lastEvent =
      Rxn<MaintenanceModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = MaintenanceModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static MaintenanceModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<MaintenanceModuleRefreshController>(tag: tag)) {
      return Get.find<MaintenanceModuleRefreshController>(tag: tag);
    }
    return Get.put(
      MaintenanceModuleRefreshController(),
      tag: tag,
      permanent: true,
    );
  }
}
