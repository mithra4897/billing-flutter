import '../../screen.dart';

class HrModuleRefreshEvent {
  const HrModuleRefreshEvent({required this.sequence, required this.source});

  final int sequence;
  final String source;
}

class HrModuleRefreshController extends GetxController {
  static const String tag = 'HrModuleRefreshController';

  final Rxn<HrModuleRefreshEvent> lastEvent = Rxn<HrModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = HrModuleRefreshEvent(sequence: _sequence, source: source);
  }

  static HrModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<HrModuleRefreshController>(tag: tag)) {
      return Get.find<HrModuleRefreshController>(tag: tag);
    }
    return Get.put(HrModuleRefreshController(), tag: tag, permanent: true);
  }
}
