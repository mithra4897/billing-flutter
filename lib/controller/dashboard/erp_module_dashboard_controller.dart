import '../../screen.dart';
import '../project/project_module_refresh_controller.dart';

class ErpModuleDashboardController extends GetxController {
  ErpModuleDashboardController({
    required this.moduleKey,
    this.loader,
    this.shellTitle,
  });

  String moduleKey;
  Future<ErpDashboardSnapshot> Function(ErpDashboardTrendFilter? filter)?
  loader;
  String? shellTitle;
  final ProjectModuleRefreshController _projectRefreshController =
      ProjectModuleRefreshController.ensureRegistered();

  Future<ErpDashboardSnapshot>? snapshotFuture;
  ErpDashboardSnapshot? snapshotCache;
  bool isTrendReloading = false;
  ErpDashboardTrendFilter trendFilter = const ErpDashboardTrendFilter(
    preset: ErpDashboardTrendPreset.monthly,
  );
  Worker? _projectRefreshWorker;

  @override
  void onInit() {
    super.onInit();
    _projectRefreshWorker = ever<ProjectModuleRefreshEvent?>(
      _projectRefreshController.lastEvent,
      (event) {
        if (event == null || moduleKey != 'projects') {
          return;
        }
        reload();
      },
    );
    snapshotFuture = loadSnapshot(cacheResult: true);
  }

  @override
  void onClose() {
    _projectRefreshWorker?.dispose();
    super.onClose();
  }

  Future<ErpDashboardSnapshot> loadSnapshot({bool cacheResult = false}) async {
    final snapshot =
        await (loader?.call(trendFilter) ??
            loadErpDashboardSnapshot(moduleKey, trendFilter: trendFilter));
    if (cacheResult) {
      snapshotCache = snapshot;
    }
    return snapshot;
  }

  void updateConfig({
    required String nextModuleKey,
    required Future<ErpDashboardSnapshot> Function(
      ErpDashboardTrendFilter? filter,
    )?
    nextLoader,
    required String? nextShellTitle,
  }) {
    if (moduleKey == nextModuleKey &&
        loader == nextLoader &&
        shellTitle == nextShellTitle) {
      return;
    }
    moduleKey = nextModuleKey;
    loader = nextLoader;
    shellTitle = nextShellTitle;
    snapshotCache = null;
    isTrendReloading = false;
    trendFilter = const ErpDashboardTrendFilter(
      preset: ErpDashboardTrendPreset.monthly,
    );
    snapshotFuture = loadSnapshot(cacheResult: true);
    update();
  }

  void reload() {
    snapshotFuture = loadSnapshot(cacheResult: true);
    update();
  }

  void setCustomRange(DateTimeRange selected) {
    trendFilter = ErpDashboardTrendFilter(
      preset: ErpDashboardTrendPreset.custom,
      customRange: ErpDashboardGraphRange(
        start: selected.start,
        end: selected.end,
      ),
    );
    update();
  }

  Future<void> refreshTrendSnapshot() async {
    isTrendReloading = true;
    final future = loadSnapshot(cacheResult: true);
    snapshotFuture = future;
    update();

    try {
      await future;
    } finally {
      isTrendReloading = false;
      update();
    }
  }

  Future<void> handleTrendControlChanged(
    ErpDashboardTrendControlValue value,
  ) async {
    switch (value) {
      case ErpDashboardTrendControlValue.monthly:
        trendFilter = const ErpDashboardTrendFilter(
          preset: ErpDashboardTrendPreset.monthly,
        );
        update();
        await refreshTrendSnapshot();
      case ErpDashboardTrendControlValue.weekly:
        trendFilter = const ErpDashboardTrendFilter(
          preset: ErpDashboardTrendPreset.weekly,
        );
        update();
        await refreshTrendSnapshot();
      case ErpDashboardTrendControlValue.yearly:
        trendFilter = const ErpDashboardTrendFilter(
          preset: ErpDashboardTrendPreset.yearly,
        );
        update();
        await refreshTrendSnapshot();
      case ErpDashboardTrendControlValue.custom:
        return;
    }
  }
}
