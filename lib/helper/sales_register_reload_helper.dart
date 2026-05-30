import 'dart:async';
import 'package:get/get.dart';
import '../model/sales/sales_quotation_model.dart';
import '../model/sales/sales_order_model.dart';
import '../model/sales/sales_invoice_model.dart';
import '../model/sales/sales_delivery_model.dart';
import '../model/sales/sales_receipt_model.dart';
import '../model/sales/sales_return_model.dart';
import '../view/sales/sales_register_screens.dart';

void reloadSalesQuotationRegister() {
  if (Get.isRegistered<SalesRegisterController<SalesQuotationModel>>(tag: 'SalesQuotationRegisterController')) {
    unawaited(Get.find<SalesRegisterController<SalesQuotationModel>>(tag: 'SalesQuotationRegisterController').load());
  }
}

void reloadSalesOrderRegister() {
  if (Get.isRegistered<SalesRegisterController<SalesOrderModel>>(tag: 'SalesOrderRegisterController')) {
    unawaited(Get.find<SalesRegisterController<SalesOrderModel>>(tag: 'SalesOrderRegisterController').load());
  }
}

void reloadSalesInvoiceRegister() {
  if (Get.isRegistered<SalesRegisterController<SalesInvoiceModel>>(tag: 'SalesInvoiceRegisterController')) {
    unawaited(Get.find<SalesRegisterController<SalesInvoiceModel>>(tag: 'SalesInvoiceRegisterController').load());
  }
}

void reloadSalesDeliveryRegister() {
  if (Get.isRegistered<SalesRegisterController<SalesDeliveryModel>>(tag: 'SalesDeliveryRegisterController')) {
    unawaited(Get.find<SalesRegisterController<SalesDeliveryModel>>(tag: 'SalesDeliveryRegisterController').load());
  }
}

void reloadSalesReceiptRegister() {
  if (Get.isRegistered<SalesRegisterController<SalesReceiptModel>>(tag: 'SalesReceiptRegisterController')) {
    unawaited(Get.find<SalesRegisterController<SalesReceiptModel>>(tag: 'SalesReceiptRegisterController').load());
  }
}

void reloadSalesReturnRegister() {
  if (Get.isRegistered<SalesRegisterController<SalesReturnModel>>(tag: 'SalesReturnRegisterController')) {
    unawaited(Get.find<SalesRegisterController<SalesReturnModel>>(tag: 'SalesReturnRegisterController').load());
  }
}
