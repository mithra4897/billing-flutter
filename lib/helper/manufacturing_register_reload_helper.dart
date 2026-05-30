import 'dart:async';
import 'package:get/get.dart';
import '../model/manufacturing/production_order_model.dart';
import '../model/manufacturing/bom_model.dart';
import '../model/manufacturing/production_receipt_model.dart';
import '../model/manufacturing/production_material_issue_model.dart';
import '../view/manufacturing/manufacturing_registers.dart';

void reloadProductionOrderRegister() {
  if (Get.isRegistered<ManufacturingRegisterController<ProductionOrderModel>>(tag: 'ProductionOrderRegisterController')) {
    unawaited(Get.find<ManufacturingRegisterController<ProductionOrderModel>>(tag: 'ProductionOrderRegisterController').load());
  }
}

void reloadBomRegister() {
  if (Get.isRegistered<ManufacturingRegisterController<BomModel>>(tag: 'BomRegisterController')) {
    unawaited(Get.find<ManufacturingRegisterController<BomModel>>(tag: 'BomRegisterController').load());
  }
}

void reloadProductionReceiptRegister() {
  if (Get.isRegistered<ManufacturingRegisterController<ProductionReceiptModel>>(tag: 'ProductionReceiptRegisterController')) {
    unawaited(Get.find<ManufacturingRegisterController<ProductionReceiptModel>>(tag: 'ProductionReceiptRegisterController').load());
  }
}

void reloadProductionMaterialIssueRegister() {
  if (Get.isRegistered<ManufacturingRegisterController<ProductionMaterialIssueModel>>(tag: 'ProductionMaterialIssueRegisterController')) {
    unawaited(Get.find<ManufacturingRegisterController<ProductionMaterialIssueModel>>(tag: 'ProductionMaterialIssueRegisterController').load());
  }
}

