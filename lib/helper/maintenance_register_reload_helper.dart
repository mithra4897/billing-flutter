import 'dart:async';
import 'package:get/get.dart';
import '../view_model/maintenance/amc_contract_view_model.dart';
import '../view_model/maintenance/asset_downtime_log_view_model.dart';
import '../view_model/maintenance/maintenance_plan_view_model.dart';
import '../view_model/maintenance/maintenance_request_view_model.dart';
import '../view/maintenance/maintenance_registers.dart';

void reloadMaintenanceWorkOrderRegister() {
  if (Get.isRegistered<MaintenanceWorkOrderRegisterController>(
    tag: 'MaintenanceWorkOrderRegisterController',
  )) {
    unawaited(
      Get.find<MaintenanceWorkOrderRegisterController>(
        tag: 'MaintenanceWorkOrderRegisterController',
      ).load(),
    );
  }
}

void reloadMaintenancePlanRegister() {
  if (Get.isRegistered<MaintenancePlanViewModel>(
    tag: 'MaintenancePlanViewModel',
  )) {
    final controller = Get.find<MaintenancePlanViewModel>(
      tag: 'MaintenancePlanViewModel',
    );
    unawaited(controller.load(selectId: controller.selectedId));
  }
}

void reloadMaintenanceRequestRegister() {
  if (Get.isRegistered<MaintenanceRequestViewModel>(
    tag: 'MaintenanceRequestViewModel',
  )) {
    final controller = Get.find<MaintenanceRequestViewModel>(
      tag: 'MaintenanceRequestViewModel',
    );
    unawaited(controller.load(selectId: controller.selectedId));
  }
}

void reloadAmcContractRegister() {
  if (Get.isRegistered<AmcContractViewModel>(tag: 'AmcContractViewModel')) {
    final controller = Get.find<AmcContractViewModel>(
      tag: 'AmcContractViewModel',
    );
    unawaited(controller.load(selectId: controller.selectedId));
  }
}

void reloadAssetDowntimeLogRegister() {
  if (Get.isRegistered<AssetDowntimeLogViewModel>(
    tag: 'AssetDowntimeLogViewModel',
  )) {
    final controller = Get.find<AssetDowntimeLogViewModel>(
      tag: 'AssetDowntimeLogViewModel',
    );
    unawaited(controller.load(selectId: controller.selectedId));
  }
}
