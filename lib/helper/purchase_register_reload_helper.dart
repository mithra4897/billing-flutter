import 'dart:async';
import 'package:get/get.dart';
import '../model/purchase/purchase_requisition_model.dart';
import '../model/purchase/purchase_order_model.dart';
import '../model/purchase/purchase_receipt_model.dart';
import '../model/purchase/purchase_invoice_model.dart';
import '../model/purchase/purchase_payment_model.dart';
import '../model/purchase/purchase_return_model.dart';
import '../view/purchase/purchase_register_screens.dart';

void reloadPurchaseRequisitionRegister() {
  if (Get.isRegistered<PurchaseListRegisterController<PurchaseRequisitionModel>>(tag: 'PurchaseRequisitionRegisterController')) {
    unawaited(Get.find<PurchaseListRegisterController<PurchaseRequisitionModel>>(tag: 'PurchaseRequisitionRegisterController').load());
  }
}

void reloadPurchaseOrderRegister() {
  if (Get.isRegistered<PurchaseListRegisterController<PurchaseOrderModel>>(tag: 'PurchaseOrderRegisterController')) {
    unawaited(Get.find<PurchaseListRegisterController<PurchaseOrderModel>>(tag: 'PurchaseOrderRegisterController').load());
  }
}

void reloadPurchaseReceiptRegister() {
  if (Get.isRegistered<PurchaseListRegisterController<PurchaseReceiptModel>>(tag: 'PurchaseReceiptRegisterController')) {
    unawaited(Get.find<PurchaseListRegisterController<PurchaseReceiptModel>>(tag: 'PurchaseReceiptRegisterController').load());
  }
}

void reloadPurchaseInvoiceRegister() {
  if (Get.isRegistered<PurchaseListRegisterController<PurchaseInvoiceModel>>(tag: 'PurchaseInvoiceRegisterController')) {
    unawaited(Get.find<PurchaseListRegisterController<PurchaseInvoiceModel>>(tag: 'PurchaseInvoiceRegisterController').load());
  }
}

void reloadPurchasePaymentRegister() {
  if (Get.isRegistered<PurchaseListRegisterController<PurchasePaymentModel>>(tag: 'PurchasePaymentRegisterController')) {
    unawaited(Get.find<PurchaseListRegisterController<PurchasePaymentModel>>(tag: 'PurchasePaymentRegisterController').load());
  }
}

void reloadPurchaseReturnRegister() {
  if (Get.isRegistered<PurchaseListRegisterController<PurchaseReturnModel>>(tag: 'PurchaseReturnRegisterController')) {
    unawaited(Get.find<PurchaseListRegisterController<PurchaseReturnModel>>(tag: 'PurchaseReturnRegisterController').load());
  }
}
