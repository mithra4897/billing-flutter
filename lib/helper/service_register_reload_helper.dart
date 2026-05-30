import 'dart:async';
import 'package:get/get.dart';
import '../model/service/service_contract_model.dart';
import '../model/service/service_ticket_model.dart';
import '../model/service/service_work_order_model.dart';
import '../model/service/service_feedback_model.dart';
import '../view/service/service_registers.dart';

void reloadServiceContractRegister() {
  if (Get.isRegistered<ServiceRegisterController<ServiceContractModel>>(
    tag: 'ServiceContractRegisterController',
  )) {
    unawaited(
      Get.find<ServiceRegisterController<ServiceContractModel>>(
        tag: 'ServiceContractRegisterController',
      ).load(),
    );
  }
}

void reloadServiceTicketRegister() {
  if (Get.isRegistered<ServiceRegisterController<ServiceTicketModel>>(
    tag: 'ServiceTicketRegisterController',
  )) {
    unawaited(
      Get.find<ServiceRegisterController<ServiceTicketModel>>(
        tag: 'ServiceTicketRegisterController',
      ).load(),
    );
  }
}

void reloadServiceWorkOrderRegister() {
  if (Get.isRegistered<ServiceRegisterController<ServiceWorkOrderModel>>(
    tag: 'ServiceWorkOrderRegisterController',
  )) {
    unawaited(
      Get.find<ServiceRegisterController<ServiceWorkOrderModel>>(
        tag: 'ServiceWorkOrderRegisterController',
      ).load(),
    );
  }
}

void reloadServiceFeedbackRegister() {
  if (Get.isRegistered<ServiceRegisterController<ServiceFeedbackModel>>(
    tag: 'ServiceFeedbackRegisterController',
  )) {
    unawaited(
      Get.find<ServiceRegisterController<ServiceFeedbackModel>>(
        tag: 'ServiceFeedbackRegisterController',
      ).load(),
    );
  }
}

void reloadWarrantyClaimRegister() {
  if (Get.isRegistered<ServiceRegisterController<ServiceTicketModel>>(
    tag: 'WarrantyClaimRegisterController',
  )) {
    unawaited(
      Get.find<ServiceRegisterController<ServiceTicketModel>>(
        tag: 'WarrantyClaimRegisterController',
      ).load(),
    );
  }
}
