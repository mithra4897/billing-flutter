import '../../screen.dart';

class SalesModuleRefreshEvent {
  const SalesModuleRefreshEvent({required this.sequence, required this.source});

  final int sequence;
  final String source;
}

class SalesModuleRefreshController extends GetxController {
  static const String tag = 'SalesModuleRefreshController';

  final Rxn<SalesModuleRefreshEvent> lastEvent = Rxn<SalesModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = SalesModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static SalesModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<SalesModuleRefreshController>(tag: tag)) {
      return Get.find<SalesModuleRefreshController>(tag: tag);
    }
    return Get.put(SalesModuleRefreshController(), tag: tag, permanent: true);
  }
}
