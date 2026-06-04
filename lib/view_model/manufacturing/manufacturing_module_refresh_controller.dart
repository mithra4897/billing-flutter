import '../../../screen.dart';

class ManufacturingModuleRefreshEvent {
  const ManufacturingModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class ManufacturingModuleRefreshController extends GetxController {
  static const String tag = 'ManufacturingModuleRefreshController';

  final Rxn<ManufacturingModuleRefreshEvent> lastEvent =
      Rxn<ManufacturingModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = ManufacturingModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static ManufacturingModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<ManufacturingModuleRefreshController>(tag: tag)) {
      return Get.find<ManufacturingModuleRefreshController>(tag: tag);
    }
    return Get.put(
      ManufacturingModuleRefreshController(),
      tag: tag,
      permanent: true,
    );
  }
}
