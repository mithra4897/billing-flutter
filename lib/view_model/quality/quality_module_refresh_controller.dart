import '../../../screen.dart';

class QualityModuleRefreshEvent {
  const QualityModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class QualityModuleRefreshController extends GetxController {
  static const String tag = 'QualityModuleRefreshController';

  final Rxn<QualityModuleRefreshEvent> lastEvent =
      Rxn<QualityModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = QualityModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static QualityModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<QualityModuleRefreshController>(tag: tag)) {
      return Get.find<QualityModuleRefreshController>(tag: tag);
    }
    return Get.put(QualityModuleRefreshController(), tag: tag, permanent: true);
  }
}
