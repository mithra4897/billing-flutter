import 'dart:async';
import 'package:get/get.dart';
import '../model/inventory/opening_stock_model.dart';
import '../model/inventory/stock_issue_model.dart';
import '../model/inventory/internal_stock_receipt_model.dart';
import '../model/inventory/stock_transfer_model.dart';
import '../model/inventory/stock_damage_entry_model.dart';
import '../model/inventory/inventory_adjustment_model.dart';
import '../model/inventory/stock_movement_model.dart';
import '../model/inventory/stock_batch_model.dart';
import '../model/inventory/stock_serial_model.dart';
import '../view/inventory/inventory_registers.dart';

void reloadOpeningStockRegister() {
  if (Get.isRegistered<InventoryRegisterController<OpeningStockModel>>(tag: 'OpeningStockRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<OpeningStockModel>>(tag: 'OpeningStockRegisterController').load());
  }
}

void reloadStockIssueRegister() {
  if (Get.isRegistered<InventoryRegisterController<StockIssueModel>>(tag: 'StockIssueRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<StockIssueModel>>(tag: 'StockIssueRegisterController').load());
  }
}

void reloadInternalStockReceiptRegister() {
  if (Get.isRegistered<InventoryRegisterController<InternalStockReceiptModel>>(tag: 'InternalStockReceiptRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<InternalStockReceiptModel>>(tag: 'InternalStockReceiptRegisterController').load());
  }
}

void reloadStockTransferRegister() {
  if (Get.isRegistered<InventoryRegisterController<StockTransferModel>>(tag: 'StockTransferRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<StockTransferModel>>(tag: 'StockTransferRegisterController').load());
  }
}

void reloadStockDamageRegister() {
  if (Get.isRegistered<InventoryRegisterController<StockDamageEntryModel>>(tag: 'StockDamageRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<StockDamageEntryModel>>(tag: 'StockDamageRegisterController').load());
  }
}

void reloadInventoryAdjustmentRegister() {
  if (Get.isRegistered<InventoryRegisterController<InventoryAdjustmentModel>>(tag: 'InventoryAdjustmentRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<InventoryAdjustmentModel>>(tag: 'InventoryAdjustmentRegisterController').load());
  }
}

void reloadStockMovementRegister() {
  if (Get.isRegistered<InventoryRegisterController<StockMovementModel>>(tag: 'StockMovementRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<StockMovementModel>>(tag: 'StockMovementRegisterController').load());
  }
}

void reloadStockBatchRegister() {
  if (Get.isRegistered<InventoryRegisterController<StockBatchModel>>(tag: 'StockBatchRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<StockBatchModel>>(tag: 'StockBatchRegisterController').load());
  }
}

void reloadStockSerialRegister() {
  if (Get.isRegistered<InventoryRegisterController<StockSerialModel>>(tag: 'StockSerialRegisterController')) {
    unawaited(Get.find<InventoryRegisterController<StockSerialModel>>(tag: 'StockSerialRegisterController').load());
  }
}
