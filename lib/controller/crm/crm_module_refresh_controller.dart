import '../../screen.dart';

class CrmModuleRefreshEvent {
  const CrmModuleRefreshEvent({required this.sequence, required this.source});

  final int sequence;
  final String source;
}

class CrmModuleRefreshController extends GetxController {
  static const String tag = 'CrmModuleRefreshController';

  final Rxn<CrmModuleRefreshEvent> lastEvent = Rxn<CrmModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = CrmModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static CrmModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<CrmModuleRefreshController>(tag: tag)) {
      return Get.find<CrmModuleRefreshController>(tag: tag);
    }
    return Get.put(CrmModuleRefreshController(), tag: tag, permanent: true);
  }
}
