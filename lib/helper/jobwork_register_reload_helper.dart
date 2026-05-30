import 'dart:async';
import 'package:get/get.dart';
import '../model/jobwork/jobwork_order_model.dart';
import '../model/jobwork/jobwork_dispatch_model.dart';
import '../model/jobwork/jobwork_receipt_model.dart';
import '../model/jobwork/jobwork_charge_model.dart';
import '../view/jobwork/jobwork_registers.dart';

void reloadJobworkOrderRegister() {
  if (Get.isRegistered<JobworkRegisterController<JobworkOrderModel>>(tag: 'JobworkOrderRegisterController')) {
    unawaited(Get.find<JobworkRegisterController<JobworkOrderModel>>(tag: 'JobworkOrderRegisterController').load());
  }
}

void reloadJobworkDispatchRegister() {
  if (Get.isRegistered<JobworkRegisterController<JobworkDispatchModel>>(tag: 'JobworkDispatchRegisterController')) {
    unawaited(Get.find<JobworkRegisterController<JobworkDispatchModel>>(tag: 'JobworkDispatchRegisterController').load());
  }
}

void reloadJobworkReceiptRegister() {
  if (Get.isRegistered<JobworkRegisterController<JobworkReceiptModel>>(tag: 'JobworkReceiptRegisterController')) {
    unawaited(Get.find<JobworkRegisterController<JobworkReceiptModel>>(tag: 'JobworkReceiptRegisterController').load());
  }
}

void reloadJobworkChargeRegister() {
  if (Get.isRegistered<JobworkRegisterController<JobworkChargeModel>>(tag: 'JobworkChargeRegisterController')) {
    unawaited(Get.find<JobworkRegisterController<JobworkChargeModel>>(tag: 'JobworkChargeRegisterController').load());
  }
}

