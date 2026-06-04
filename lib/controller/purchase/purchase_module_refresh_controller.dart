import '../../screen.dart';

class PurchaseModuleRefreshEvent {
  const PurchaseModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class PurchaseModuleRefreshController extends GetxController {
  static const String tag = 'PurchaseModuleRefreshController';

  final Rxn<PurchaseModuleRefreshEvent> lastEvent =
      Rxn<PurchaseModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = PurchaseModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static PurchaseModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<PurchaseModuleRefreshController>(tag: tag)) {
      return Get.find<PurchaseModuleRefreshController>(tag: tag);
    }
    return Get.put(
      PurchaseModuleRefreshController(),
      tag: tag,
      permanent: true,
    );
  }
}
