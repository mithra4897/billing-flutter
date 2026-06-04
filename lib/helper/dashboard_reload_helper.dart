import 'dart:async';

import 'package:get/get.dart';

import '../controller/dashboard/erp_module_dashboard_controller.dart';
import 'getx_page_state.dart';

void reloadModuleDashboard(String moduleKey) {
  final tag = persistentControllerTag(
    'ErpModuleDashboardController-$moduleKey',
  );
  if (!Get.isRegistered<ErpModuleDashboardController>(tag: tag)) {
    return;
  }
  unawaited(
    Get.find<ErpModuleDashboardController>(tag: tag).refreshTrendSnapshot(),
  );
}

void reloadProjectsDashboard() {
  reloadModuleDashboard('projects');
}
