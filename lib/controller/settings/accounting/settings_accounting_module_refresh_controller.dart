import '../../../screen.dart';

class SettingsAccountingModuleRefreshEvent {
  const SettingsAccountingModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class SettingsAccountingModuleRefreshController extends GetxController {
  static const String tag = 'SettingsAccountingModuleRefreshController';

  final Rxn<SettingsAccountingModuleRefreshEvent> lastEvent =
      Rxn<SettingsAccountingModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = SettingsAccountingModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static SettingsAccountingModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<SettingsAccountingModuleRefreshController>(tag: tag)) {
      return Get.find<SettingsAccountingModuleRefreshController>(tag: tag);
    }
    return Get.put(
      SettingsAccountingModuleRefreshController(),
      tag: tag,
      permanent: true,
    );
  }
}
