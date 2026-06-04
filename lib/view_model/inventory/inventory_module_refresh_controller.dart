import '../../../screen.dart';

class InventoryModuleRefreshEvent {
  const InventoryModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class InventoryModuleRefreshController extends GetxController {
  static const String tag = 'InventoryModuleRefreshController';

  final Rxn<InventoryModuleRefreshEvent> lastEvent =
      Rxn<InventoryModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = InventoryModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static InventoryModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<InventoryModuleRefreshController>(tag: tag)) {
      return Get.find<InventoryModuleRefreshController>(tag: tag);
    }
    return Get.put(
      InventoryModuleRefreshController(),
      tag: tag,
      permanent: true,
    );
  }
}
