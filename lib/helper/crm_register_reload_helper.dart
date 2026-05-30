import 'dart:async';
import 'package:get/get.dart';
import '../controller/crm/crm_enquiries_controller.dart';
import '../controller/crm/crm_lead_register_controller.dart';
import '../controller/crm/crm_opportunities_controller.dart';
import '../controller/crm/crm_sources_controller.dart';
import '../controller/crm/crm_stages_controller.dart';

void reloadCrmLeadRegister() {
  unawaited(CrmLeadRegisterController.refreshIfRegistered());
}

void reloadCrmOpportunityRegister() {
  unawaited(CrmOpportunitiesController.refreshIfRegistered());
}

void reloadCrmEnquiryRegister() {
  unawaited(CrmEnquiriesController.refreshIfRegistered());
}

void reloadCrmSourceRegister() {
  if (Get.isRegistered<CrmSourcesController>(tag: 'CrmSourcesController')) {
    unawaited(
      Get.find<CrmSourcesController>(tag: 'CrmSourcesController').loadPage(),
    );
  }
}

void reloadCrmStageRegister() {
  if (Get.isRegistered<CrmStagesController>(tag: 'CrmStagesController')) {
    unawaited(
      Get.find<CrmStagesController>(tag: 'CrmStagesController').loadPage(),
    );
  }
}
