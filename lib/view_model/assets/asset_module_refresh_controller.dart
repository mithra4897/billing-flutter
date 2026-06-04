import '../../../screen.dart';

class AssetModuleRefreshEvent {
  const AssetModuleRefreshEvent({required this.sequence, required this.source});

  final int sequence;
  final String source;
}

class AssetModuleRefreshController extends GetxController {
  static const String tag = 'AssetModuleRefreshController';

  final Rxn<AssetModuleRefreshEvent> lastEvent = Rxn<AssetModuleRefreshEvent>();
  int _sequence = 0;

  void notifyChanged({required String source}) {
    _sequence += 1;
    lastEvent.value = AssetModuleRefreshEvent(
      sequence: _sequence,
      source: source,
    );
  }

  static AssetModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<AssetModuleRefreshController>(tag: tag)) {
      return Get.find<AssetModuleRefreshController>(tag: tag);
    }
    return Get.put(AssetModuleRefreshController(), tag: tag, permanent: true);
  }
}
