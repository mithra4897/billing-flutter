import 'dart:async';
import 'package:get/get.dart';
import '../view_model/quality/qc_non_conformance_log_view_model.dart';
import '../view_model/quality/qc_result_action_view_model.dart';
import '../view/quality/quality_registers.dart';

void reloadQcPlanRegister() {
  if (Get.isRegistered<QcPlanRegisterController>(
    tag: 'QcPlanRegisterController',
  )) {
    unawaited(
      Get.find<QcPlanRegisterController>(
        tag: 'QcPlanRegisterController',
      ).load(),
    );
  }
}

void reloadQcInspectionRegister() {
  if (Get.isRegistered<QcInspectionRegisterController>(
    tag: 'QcInspectionRegisterController',
  )) {
    unawaited(
      Get.find<QcInspectionRegisterController>(
        tag: 'QcInspectionRegisterController',
      ).load(),
    );
  }
}

void reloadQcResultActionRegister() {
  if (Get.isRegistered<QcResultActionViewModel>(
    tag: 'QcResultActionViewModel',
  )) {
    final controller = Get.find<QcResultActionViewModel>(
      tag: 'QcResultActionViewModel',
    );
    unawaited(controller.load(selectId: controller.selected?.id));
  }
}

void reloadQcNonConformanceLogRegister() {
  if (Get.isRegistered<QcNonConformanceLogViewModel>(
    tag: 'QcNonConformanceLogViewModel',
  )) {
    final controller = Get.find<QcNonConformanceLogViewModel>(
      tag: 'QcNonConformanceLogViewModel',
    );
    unawaited(controller.load(selectId: controller.selected?.id));
  }
}
